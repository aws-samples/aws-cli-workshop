#!/bin/bash
export RUST_LOG=aws_config::profile=info,aws_smithy_http_tower=debug
cd shared-cfg-demo
cargo run
