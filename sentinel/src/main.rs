// This is just a simple template, to be used as a starting point for the project.
// TODO: port for node in Config struct
// TODO: task2 logic
// TODO: events filter to include "start date" and "valid event" of the smart contract
// TODO: update function naming to be more descriptive
// TODO: function to check / create TABLES in the database
// TODO: loop to fetch events from the smart contract - channels and providers
// TODO: loop to validate which channels needs to be "executed" based on the "payment date" -> keeps the "channels" in a cache
// TODO: - the loop above = use cache to avoid fetching the same data multiple times
//          - ON TOP of the cache are "channels" that needs to be processed earlier
// TODO: create a function to process the "channels" that needs to be processed
//      - add mechanism to avoid processing the same "channel" multiple times

use sqlx::{postgres::PgPoolOptions, sqlite::SqlitePoolOptions, Pool, Postgres, Sqlite};
use std::env;
use std::fs;
use std::path::PathBuf;
use tokio;
use web3::transports::Http;
use web3::types::{Address, FilterBuilder};

struct Config {
    ethereum_node_url: String,
    network_id: u64,
    smart_contract_address: Address,
    db_url: String,
}

#[tokio::main]
async fn main() {
    let config = load_config().expect("Failed to load configuration");

    let pool = match config.db_url.as_str() {
        None | Some("") => init_sqlite().await,
        _ => init_postgresql(&config.db_url).await,
    };

    if let Err(e) = verify_network_id(&config).await {
        eprintln!("Network ID verification failed: {}", e);
        return;
    }

    if let Err(e) = task1(&pool, &config).await {
        eprintln!("Error in task 1: {}", e);
    }

    if let Err(e) = task2(&pool, &config).await {
        eprintln!("Error in task 2: {}", e);
    }
}

fn load_config() -> Result<Config, Box<dyn std::error::Error>> {
    let db_url = env::var("DB_URL")?;
    let ethereum_node_url = env::var("ETHEREUM_NODE_URL")?;
    let smart_contract_address: Address = env::var("SMART_CONTRACT_ADDRESS")?.parse()?;
    let network_id: u64 = env::var("NETWORK_ID")?.parse()?;

    Ok(Config {
        ethereum_node_url,
        network_id,
        smart_contract_address,
        db_url,
    })
}

async fn init_sqlite() -> Pool<Sqlite> {
    let db_path = PathBuf::from("data").join("sentinel.db");
    fs::create_dir_all(db_path.parent().unwrap())?;

    let db_url = format!("sqlite:{}", db_path.display());

    return SqlitePoolOptions::new()
        .connect(&db_url)
        .await
        .expect("Failed to create SQLite pool");
}

async fn init_postgresql(db_url: &str) -> Pool<Postgres> {
    PgPoolOptions::new()
        .connect(db_url)
        .await
        .expect("Failed to create PostgreSQL pool")
}

async fn verify_network_id(config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    let web3 = web3::Web3::new(Http::new(&config.ethereum_node_url)?);
    let network_id = web3.net().version().await?.parse::<u64>()?;

    if network_id != config.network_id {
        Err(format!(
            "Expected network ID {}, but got {}",
            config.network_id, network_id
        )
        .into())
    } else {
        Ok(())
    }
}

async fn task1(
    pool: &Pool<impl sqlx::Database>,
    config: &Config,
) -> Result<(), Box<dyn std::error::Error>> {
    let web3 = web3::Web3::new(Http::new(&config.ethereum_node_url)?);
    let contract = web3
        .eth()
        .contract(config.smart_contract_address, Default::default());

    // Fetch events asynchronously
    let events = fetch_events_task1(&contract, pool).await?;

    // Save to database in parallel
    save_events_to_db_task1(&config.smart_contract_address, events, pool).await;

    Ok(())
}

async fn fetch_events_task1(
    contract: &web3::Contract,
    pool: &Pool<impl sqlx::Database>,
) -> Result<Vec<EventTask1>, Box<dyn std::error::Error>> {
    let filter = FilterBuilder::default()
        .address(vec![contract.address()])
        .build();

    let logs = contract.web3().eth().logs(filter).await?;
    Ok(logs.into_iter().map(|log| EventTask1::from(log)).collect())
}

async fn task2(
    pool: &Pool<impl sqlx::Database>,
    config: &Config,
) -> Result<(), Box<dyn std::error::Error>> {
    // Fetch addresses from the database
    let addresses = fetch_addresses(pool).await?;

    // Process events for each address in parallel
    for address in addresses {
        let _ = tokio::spawn(async move {
            process_address_events(&address, pool, config).await;
        });
    }

    Ok(())
}

async fn save_events_to_db_task1(
    address: &Address,
    events: Vec<EventTask1>,
    pool: &Pool<impl sqlx::Database>,
) {
    let tasks: Vec<_> = events.into_iter().map(|event| {
        let pool = pool.clone();
        tokio::spawn(async move {
            sqlx::query("INSERT INTO events_task1 (contract_address, address, provider_id) VALUES (?, ?, ?)")
                .bind(contract_address)
                .bind(event.address)
                .bind(event.provider_id)
                .execute(&pool)
                .await
                .expect("Failed to save event");
        })
    }).collect();
    futures::future::join_all(tasks).await;
}

async fn save_events_to_db_task2(
    address: &Address,
    events: Vec<EventTask2>,
    pool: &Pool<impl sqlx::Database>,
) {
    let tasks: Vec<_> = events
        .into_iter()
        .map(|event| {
            let pool = pool.clone();
            let calculated_address = calculate_keccak_address(&event.channel_id);
            tokio::spawn(async move {
                sqlx::query("INSERT INTO events_task2 (address, channel_id) VALUES (?, ?)")
                    .bind(calculated_address)
                    .bind(event.channel_id)
                    .execute(&pool)
                    .await
                    .expect("Failed to save event");
            })
        })
        .collect();
    futures::future::join_all(tasks).await;
}

async fn fetch_addresses(
    pool: &Pool<impl sqlx::Database>,
) -> Result<Vec<Address>, Box<dyn std::error::Error>> {
    let rows = sqlx::query!("SELECT address FROM events_task1")
        .fetch_all(pool)
        .await?;
    Ok(rows.into_iter().map(|row| row.address).collect())
}

async fn process_address_events(
    address: &Address,
    pool: &Pool<impl sqlx::Database>,
    config: &Config,
) {
    let web3 = web3::Web3::new(Http::new(&config.ethereum_node_url)?);

    let filter = FilterBuilder::default().address(vec![*address]).build();

    let logs = web3.eth().logs(filter).await.expect("Failed to fetch logs");
    let events: Vec<EventTask2> = logs.into_iter().map(|log| EventTask2::from(log)).collect();

    save_events_to_db_task2(address, events, pool).await;
}

fn calculate_keccak_address(data: &[u8; 32]) -> Address {
    let hash = Keccak256::digest(data);
    Address::from_slice(&hash[12..])
}

struct EventTask1 {
    address: Address,
    provider_id: [u8; 32],
}

impl From<web3::types::Log> for EventTask1 {
    fn from(log: web3::types::Log) -> Self {
        Self {
            address: log.address,
            provider_id: log.topics[1].as_fixed_bytes().clone(),
        }
    }
}

struct EventTask2 {
    channel_id: [u8; 32],
}

impl From<web3::types::Log> for EventTask2 {
    fn from(log: web3::types::Log) -> Self {
        Self {
            channel_id: log.topics[1].as_fixed_bytes().clone(),
        }
    }
}
