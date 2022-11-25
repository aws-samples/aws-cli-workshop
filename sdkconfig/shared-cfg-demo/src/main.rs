use aws_config::meta::region::RegionProviderChain;
use aws_sdk_ecs::{Client, Error};

/// Lists your DynamoDB tables in the default Region or us-east-1 if a default Region isn't set.
#[tokio::main]
async fn main() -> Result<(), Error> {
    env_logger::init();
    let region_provider = RegionProviderChain::default_provider().or_else("us-west-2");
    let config = aws_config::from_env().region(region_provider).load().await;
    let client = Client::new(&config);

    let resp = client.list_clusters().send().await?;

    println!("Clusters:");

    let arns = resp.cluster_arns().unwrap_or_default();

    for arn in arns {
        println!("  {}", arn);
    }

    Ok(())
}
