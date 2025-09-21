deploy:
	@forge script script/$(contract).s.sol \
		--rpc-url $(network) \
		--account $(from) \
		--broadcast \
		--verify \
		--verifier blockscout \
		--verifier-url 'https://gensyn-testnet.explorer.alchemy.com/api/' \
		--sig "deploy()"