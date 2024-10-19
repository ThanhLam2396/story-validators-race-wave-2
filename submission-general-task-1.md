
# **Story Validator Node Setup Script - Documentation**

## **I. Overview**

This script automates the installation, configuration, and management of the Story Validator Node, simplifying operations by handling dependencies, binaries, system services, wallets, and syncing tasks. It provides a menu-driven interface that allows users to perform actions such as checking logs, managing node synchronization, and updating configurations.

----------

## **II. System Requirements**

1.  **OS:** Ubuntu-based distributions

2.  **Privileges:** Root or sudo access

3.  **Network Access:** Required to download dependencies, binaries, and snapshots.

* * * * *

## **III. Installation Guide**

### **Step 1: Script Setup**

1. Open a terminal.

2. Download the script (save it as `install_story.sh`).

3. Provide execution permission:

	`chmod +x install_story.sh`

4. Run the script:

	`./install_story.sh`
<img width="1265" alt="main" src="https://github.com/user-attachments/assets/9d5a5018-7db7-4e5a-bcd8-9407809a861f">

----------

**NOTE:** This section provides an in-depth look at each feature available in the Story Validator Node setup script. Every feature is explained with the following structure:

-  **Feature Name and Number:** Corresponding menu option from the script.

-  **Purpose:** Describes the importance of the feature and how it benefits the user.

-  **Usage:** Step-by-step instructions on how to use the feature based on the code logic.

----------

## ** Main Features and Usage**

**1\. Install Story Node**

#### **Purpose:**

This feature is essential as it provides a **one-stop installation process** for the Story Validator Node. It handles everything: **dependency management, binary installation, and configuration**, ensuring your node is ready to run seamlessly in no time. This option simplifies what would otherwise be a complex multi-step process, making it accessible even to beginners.

#### **Usage:**

1. Select **"Install Story Node "** from the main menu.

2. Follow these prompts:

	- Enter a **validator name**.

	- Choose whether to **change default ports**.

	- If yes, enter new prefixes for:

	- Proxy App Port (26658)

	- RPC Port (26657)

	- P2P Port (26656)

3. The script will:

	- Install dependencies and Go.

	- Clone the Story and Geth binaries.

	- Set up the **systemd services** for automatic management.

	- Sync using the **latest snapshot**.

* * * * *

**2\. Check Story Logs**


#### **Purpose:**

This feature provides **real-time monitoring of the Story Node's logs**, which is essential for tracking your node's performance and diagnosing any issues quickly. By watching the logs, you can detect synchronization issues, service disruptions, or configuration errors as they occur.

#### **Usage:**

1. Select **"Check Story Logs"** from the menu.

2. The logs will display in real-time on the screen.

3. Use **Ctrl + C** to exit the logs view.

* * * * *

**3\. Check Geth Logs**


#### **Purpose:**

This feature enables you to **monitor the Geth client logs**, which is crucial if your node interacts with Ethereum-based networks. Geth logs help ensure that your node stays connected and synced with the blockchain.

#### **Usage:**

1. Select **"Check Geth Logs"** from the menu.

2. The logs will display in real-time.

3. Use **Ctrl + C** to stop viewing the logs.

* * * * *

**4\. Check Sync Status**


#### **Purpose:**

This option checks the **current sync status** of the node, including the local and network block heights. Staying synced with the blockchain ensures the node can validate transactions and participate in consensus correctly.

#### **Usage:**

1. Select **"Check Sync Status"** from the menu.

2. The script will:

- Fetch the **local and network heights**.

- Calculate the **blocks remaining** and estimate the sync time.

3. View the sync progress on-screen.

* * * * *

**5\. Check Sync Info**


#### **Purpose:**

This feature provides **detailed synchronization information**, offering a deeper look at the node's current sync state. It is useful for debugging and ensuring your node is aligned with the blockchain.

#### **Usage:**

1. Select **"Check Sync Info"** from the menu.

2. The script will retrieve and display sync details using the RPC interface.

* * * * *

**6\. Check Validator Info**


#### **Purpose:**

This option displays critical information about your validator, including its **status, ID, and other relevant data**. This is essential for monitoring the health of your validator and ensuring it remains active in the network.

#### **Usage:**

1. Select **"Check Validator Info"** from the menu.

2. The validator's status will be shown on-screen.

* * * * *

**7\. Synchronization via Snapshot**


#### **Purpose:**

This feature allows you to **synchronize the node using the latest snapshot**, significantly speeding up the sync process. Instead of syncing from scratch, snapshots provide a recent state of the blockchain.

#### **Usage:**

1. Select **"Synchronization via Snapshot"** from the menu.

2. Confirm synchronization by selecting **"yes"** when prompted.

3. The script will:

- Stop the services.

- Download and extract the latest snapshot.

- Restart the services for the node to continue syncing from the snapshot.

* * * * *

**8\. Update Seed**

#### **Purpose:**

This feature updates the **seed node configuration**, helping the node connect to other peers more efficiently. Keeping seeds updated ensures stable connections within the network.

#### **Usage:**

1. Select **"Update New Seed"** from the menu.

2. Enter the **new seed** in the format: `node_id@ip:port`.

3. The configuration will be updated and verified.

* * * * *

**9\. Sync New Live-Peers**

#### **Purpose:**

This feature fetches **live peers** from the network and updates the configuration with their details. Maintaining an up-to-date list of peers enhances connectivity and synchronization.

#### **Usage:**

1. Select **"Sync New Live-Peers"** from the menu.

2. The script will fetch live peers and update the **persistent_peers** field in the configuration.

* * * * *

**10\. Clear Persistent Peers**


#### **Purpose:**

This option clears all existing **persistent peers** from the configuration. Use this when you encounter connectivity issues or want to reset the peer list.

#### **Usage:**

1. Select **"Clear Persistent Peers"** from the menu.

2. The script will remove the peer list from the configuration.

* * * * *

**11\. Check Story Version**


#### **Purpose:**

Displays the **current version of the Story Node and Geth**. This helps ensure you are using the latest version for compatibility and security.

####**Usage:**

1. Select **"Check Story Version"** from the menu.

2. View the versions displayed on-screen.

* * * * *

**12\. Upgrade Story Version**


#### **Purpose:**

This option upgrades the Story binaries to the **latest version**, ensuring your node remains compatible with the network's latest updates.

#### **Usage:**

1. Select **"Upgrade Story Version"** from the menu.

2. The script will download and install the latest binaries.

* * * * *

**13\. Create Wallet**


#### **Purpose:**

Creates a **new wallet** for your node and exports the private key. This wallet is essential for validator operations.

#### **Usage:**

1. Select **"Create Wallet"** from the menu.

2. Enter the **wallet name** when prompted.

3.  **Save the private key** securely when displayed.

* * * * *

**14\. Check Wallet Info**


#### **Purpose:**

Displays information about the wallet you have created, including essential details for managing your assets.

#### **Usage:**

1. Select **"Check Wallet Info"** from the menu.

2. The wallet details will be shown on-screen.

* * * * *

**15\. Check Wallet Balance**


#### **Purpose:**

This option allows you to **check the wallet's balance** using an EVM address.

#### **Usage:**

1. Select **"Check Wallet Balance"** from the menu.

2. Enter the **EVM address** when prompted.

3. View the balance in ETH format.

* * * * *

**16\. Restart Story Node**


#### **Purpose:**

Restarts the **Story and Geth services**, useful after making configuration changes or encountering issues.

#### **Usage:**

1. Select **"Restart Story Node"** from the menu.

2. The services will restart, and logs will be displayed.

* * * * *

**17\. Stop Story Node**

#### **Purpose:**

Stops the Story and Geth services when maintenance or updates are needed.

#### **Usage:**

1. Select **"Stop Story Node"** from the menu.

2. The services will be stopped.

* * * * *

**18\. Delete Story Node**

#### **Purpose:**

This option **removes the node and all its data**, useful if you need to reconfigure or uninstall the node.

#### **Usage:**

1. Select **"Delete Story Node"** from the menu.

2. Confirm deletion by typing **"yes"**.

* * * * *

**19\. Help**

#### **Purpose:**

Displays a **detailed help menu** with descriptions of all features, guiding users through the available options.

#### **Usage:**

1. Select **"Help"** from the menu.

2. Browse the help content displayed on-screen.

* * * * *

**20\. Exit**

 **Purpose:**

Exit the script safely.

 **Usage:**

1. Select **"Exit"** from the menu.

2. The script will close.

* * * * *

**Conclusion**

--------------

The Story Validator Node script streamlines the entire process of managing a blockchain node. With automated installation, real-time monitoring, and syncing capabilities, it ensures that users can focus on operating their validator efficiently. This comprehensive documentation serves as a guide to harness the full potential of the script and maintain a healthy, functional node in the network.
