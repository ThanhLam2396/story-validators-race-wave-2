from prometheus_client import start_http_server, Gauge, Summary, Info
import requests
import time
import os
from dotenv import load_dotenv

load_dotenv()

# Cấu hình từ file .env
NODE_OPERATOR = os.getenv("NODE_OPERATOR")
RPC_ENDPOINT = os.getenv("RPC_ENDPOINT")
API_BASE_URL = os.getenv("API_BASE_URL")

# Định nghĩa các metrics cho Prometheus
node_block_height = Gauge('node_block_height', 'Current block height of the node')
node_sync_status = Gauge('node_sync_status', 'Node sync status (1 = in sync, 0 = catching up)')
tm_peers = Gauge('tm_peers', 'Number of Tendermint peers')
validators_active = Gauge('validators_active', 'Active validators', ['network_name', 'token_alias'])
validators_total = Gauge('validators_total', 'Total validators', ['node_operator'])
api_block_height = Gauge('api_block_height', 'Latest block height from API')

# Info metric cho Token
token_info = Info('token_info', 'Token information including denom and alias')

# Metrics cho Delegators và Validators
delegator_amount = Gauge('delegator_amount', 'Amount delegated by a delegator', ['delegator_address'])
validator_tokens = Gauge('validator_tokens', 'Tokens held by a validator', ['moniker', 'operator_address'])
validator_tombstoned = Gauge('validator_tombstoned', 'Whether the validator is tombstoned', ['operator_address'])
validator_jailed = Gauge('validator_jailed', 'Whether the validator is jailed', ['operator_address'])
validator_commission_rate = Gauge('validator_commission_rate', 'Commission rate of the validator', ['moniker'])
validator_voting_power_percent = Gauge('validator_voting_power_percent', 'Voting power percent of the validator', ['moniker'])

# Info metric cho Validators
validator_info = Info('validator_info', 'General information about the validator')

# Metrics cho Tokenomics
token_supply = Gauge('token_supply', 'Total token supply of the chain')
token_bonded = Gauge('token_bonded', 'Total bonded tokens of the chain')

# Đo thời gian phản hồi RPC
rpc_response_time = Summary('rpc_response_time_seconds', 'RPC response time in seconds')

# Các URL cần thiết
validatorinfo_url = f"{API_BASE_URL}/validators/{NODE_OPERATOR}"
urldelegators = f"{validatorinfo_url}/delegations"
netinfostory = f"{API_BASE_URL}/chain/network"
tokenomics_url = f"{API_BASE_URL}/chain/tokenomics"

def fetch_json(url, timeout=5):
    """Gửi yêu cầu GET và trả về dữ liệu JSON."""
    try:
        start_time = time.time()
        response = requests.get(url, timeout=timeout)
        response.raise_for_status()
        rpc_response_time.observe(time.time() - start_time)
        data = response.json()
        print(f"Response from {url}: {data}")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Lỗi khi gọi API: {e}")
        return {}

def collect_metrics():
    """Thu thập và xuất các metrics."""
    while True:
        try:
            # Thu thập thông tin từ RPC
            status_data = fetch_json(f"{RPC_ENDPOINT}/status")
            net_info_data = fetch_json(f"{RPC_ENDPOINT}/net_info")

            # Cập nhật block height và số lượng peers
            block_height = int(status_data["result"]["sync_info"]["latest_block_height"])
            peers_count = int(net_info_data["result"]["n_peers"])
            is_syncing = status_data["result"]["sync_info"]["catching_up"]

            node_block_height.set(block_height)
            node_sync_status.set(0 if is_syncing else 1)
            tm_peers.set(peers_count)

            # Thu thập dữ liệu từ API Story
            network_data = fetch_json(netinfostory)
            validator_info_data = fetch_json(validatorinfo_url)
            tokenomics_data = fetch_json(tokenomics_url)

            # Lấy thông tin token (denom và alias)
            token_data = network_data.get('token', {})
            denom = token_data.get('denom', 'unknown')
            alias = token_data.get('alias', 'unknown')

            # Xuất Info metric cho Token
            token_info.info({
                'denom': denom,
                'alias': alias
            })
            print(f"Token Denom: {denom}, Token Alias: {alias}")

            # Lấy và xuất thông tin về validators
            network_name = network_data.get('network', 'unknown')
            latest_block = int(network_data.get('latestBlock', {}).get('height', 0))
            token_alias = token_data.get('alias', 'unknown')

            validators_active.labels(network_name, token_alias).set(
                int(network_data['validators']['active'])
            )
            validators_total.labels(NODE_OPERATOR).set(int(network_data['validators']['total']))
            api_block_height.set(latest_block)

            print(f"Latest Block Height: {latest_block}")

            # Xuất metrics cho Validator
            moniker = validator_info_data.get('moniker', 'unknown')
            operator_address = validator_info_data.get('operator_address', 'unknown')
            hex_address = validator_info_data.get('hexAddress', 'unknown')
            account_address = validator_info_data.get('accountAddress', 'unknown')
            tokens = float(validator_info_data.get('tokens', 0))
            commission_rate = float(validator_info_data['commission']['commission_rates']['rate'])
            voting_power_percent = float(validator_info_data.get('votingPowerPercent', 0))
            tombstoned = validator_info_data['signingInfo'].get('tombstoned', False)
            jailed = validator_info_data.get('jailed', False)

            # Xuất Info metric cho Validator
            validator_info.info({
                'moniker': moniker,
                'operator_address': operator_address,
                'hex_address': hex_address,
                'account_address': account_address
            })

            validator_tokens.labels(moniker=moniker, operator_address=operator_address).set(tokens)
            validator_commission_rate.labels(moniker=moniker).set(commission_rate)
            validator_voting_power_percent.labels(moniker=moniker).set(voting_power_percent)
            validator_tombstoned.labels(operator_address=operator_address).set(1 if tombstoned else 0)
            validator_jailed.labels(operator_address=operator_address).set(1 if jailed else 0)

            print(f"""
Moniker: {moniker}
Operator Address: {operator_address}
Hex Address: {hex_address}
Account Address: {account_address}
Tokens: {tokens}
Commission Rate: {commission_rate}
Voting Power Percent: {voting_power_percent}
Tombstoned: {tombstoned}
Jailed: {jailed}
""")

            # Thu thập và xuất metrics cho Delegators
            delegators_data = fetch_json(urldelegators)
            for item in delegators_data.get('items', []):
                address = item['delegator']['address']
                amount = float(item['amount'])
                delegator_amount.labels(delegator_address=address).set(amount)
                print(f"Delegator: {address}, Amount: {amount}")

            # Xuất metrics cho Tokenomics
            tokenomics = tokenomics_data.get('tokenomics', {})
            supply = float(tokenomics.get('supply', 0))
            bonded = float(tokenomics.get('bonded', 0))

            token_supply.set(supply)
            token_bonded.set(bonded)

            print(f"Token Supply: {supply}, Token Bonded: {bonded}")

        except Exception as e:
            print(f"Lỗi khi thu thập metrics: {e}")

        time.sleep(3)

if __name__ == '__main__':
    start_http_server(8888)
    collect_metrics()