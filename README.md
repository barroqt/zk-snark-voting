# Private voting system

This is a private voting system using zk-snarks deployed on Scroll sepolia.
The contract is verified: https://sepolia.scrollscan.com/address/0xEc30cC5bAF0E2ed78A23c015509Def4e9DAdb52a

TODO:

- Replace mapping(address => Voter) with a Merkle root of voter commitments.
- Modify addVoter to update the Merkle root instead of directly storing voter data.
- Change setVote to accept a ZK proof and encrypted vote data instead of a plain proposal ID.
- Implement a new function to verify ZK proofs for voting.
- Modify tallyVotes to work with encrypted or committed vote data.
- Add functions for voters to generate and verify their inclusion proofs off-chain.
- Designing the specific ZK circuits for voter registration and vote casting.
- Implementing the off-chain components for generating ZK proofs.
- Integrating a ZK-SNARK verification library into the contract.
- Implementing a privacy-preserving vote tallying mechanism.

## Usage

Admin adds voters => voters submit proposals => Voters vote for proposals => Vote tally

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
