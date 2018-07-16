# Credential Recovery Identity Kit

> 🕵️ [Find more boilerplates using GitHub](https://github.com/search?q=topic:aragon-boilerplate)

This is an Aragon kit for a persistent identity with recoverable credentials. It includes an Identity app so that calls can be forwarded to any non-aragon DApps. It also allows other aragon apps to be directly integrated into it. When you create your credential recoverable identity, you must specify a third party that will be able to recover your credentials. There are a few suggested options:

- Another contract that you control yourself, in a more secure way.
- A Decentralized Organization that you already participate in.
- Null, so that you can create a decentralized organization which the identity is a part of to change it to.
- A centralized third party that you mildly trust.

You can change the third party at any time. Any interaction with the blockchain will require two transactions - one to initiate the transaction, and another after a delay to complete the transaction. These can be canceled at any time. The contract code will protect you in all of the following situations, as long as you act appropriately:

- If you lose your credentials, you will be able to go to the third party to recover it.
- If an attacker steals your credentials, you will be able to cancel all transactions they made before the delay period ends, and revoke your own credentials. At that point you will be able to recover your credentials with the third party. The new credentials will not be compromised, and you will be able to continue interacting with DApps without any transactions from the attacker completed.
- If an attacker compromises the third party, either because you trusted someone you shouldn't have or because a majority of the multisig is compromised, you will not lose access to your account. Any credential reset they attempt can be canceled during the delay, and the third party can be changed to someone else.
