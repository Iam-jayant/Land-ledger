const LandRegistry = artifacts.require("LandRegistry");
const EscrowManager = artifacts.require("EscrowManager");
const DocumentVerification = artifacts.require("DocumentVerification");

module.exports = async function (deployer, network, accounts) {
  console.log("Deploying LandLedger contracts...");
  console.log("Network:", network);
  console.log("Deployer account:", accounts[0]);

  try {
    // Deploy DocumentVerification first
    console.log("Deploying DocumentVerification...");
    await deployer.deploy(DocumentVerification);
    const documentVerification = await DocumentVerification.deployed();
    console.log("DocumentVerification deployed at:", documentVerification.address);

    // Deploy EscrowManager
    console.log("Deploying EscrowManager...");
    await deployer.deploy(EscrowManager);
    const escrowManager = await EscrowManager.deployed();
    console.log("EscrowManager deployed at:", escrowManager.address);

    // Deploy LandRegistry (main contract)
    console.log("Deploying LandRegistry...");
    await deployer.deploy(LandRegistry);
    const landRegistry = await LandRegistry.deployed();
    console.log("LandRegistry deployed at:", landRegistry.address);

    // Setup initial configuration
    console.log("Setting up initial configuration...");

    // Grant roles to LandRegistry contract in other contracts
    const LAND_INSPECTOR_ROLE = web3.utils.keccak256("LAND_INSPECTOR_ROLE");
    const ESCROW_AGENT_ROLE = web3.utils.keccak256("ESCROW_AGENT_ROLE");
    const VERIFIER_ROLE = web3.utils.keccak256("VERIFIER_ROLE");
    const DOCUMENT_MANAGER_ROLE = web3.utils.keccak256("DOCUMENT_MANAGER_ROLE");

    // Grant LandRegistry contract permission to create escrows
    await escrowManager.grantRole(ESCROW_AGENT_ROLE, landRegistry.address);
    console.log("Granted ESCROW_AGENT_ROLE to LandRegistry");

    // Grant LandRegistry contract permission to manage documents
    await documentVerification.grantRole(DOCUMENT_MANAGER_ROLE, landRegistry.address);
    console.log("Granted DOCUMENT_MANAGER_ROLE to LandRegistry");

    // Setup additional inspectors if needed (for development)
    if (network === 'development' || network === 'ganache' || network === 'local') {
      console.log("Setting up development inspectors...");
      
      // Add additional inspectors for testing
      if (accounts.length > 1) {
        await landRegistry.addLandInspector(
          accounts[1],
          "Inspector Mumbai",
          40,
          "Sub-Registrar",
          "Mumbai District"
        );
        console.log("Added Inspector Mumbai:", accounts[1]);

        await landRegistry.addLandInspector(
          accounts[2],
          "Inspector Delhi",
          45,
          "Registrar",
          "Delhi NCR"
        );
        console.log("Added Inspector Delhi:", accounts[2]);

        // Grant verifier roles to inspectors in DocumentVerification
        await documentVerification.grantRole(VERIFIER_ROLE, accounts[1]);
        await documentVerification.grantRole(VERIFIER_ROLE, accounts[2]);
        console.log("Granted VERIFIER_ROLE to inspectors");

        // Grant inspector roles in EscrowManager
        await escrowManager.grantRole(LAND_INSPECTOR_ROLE, accounts[1]);
        await escrowManager.grantRole(LAND_INSPECTOR_ROLE, accounts[2]);
        console.log("Granted LAND_INSPECTOR_ROLE to inspectors in EscrowManager");
      }
    }

    console.log("\n=== LandLedger Deployment Summary ===");
    console.log("LandRegistry:", landRegistry.address);
    console.log("EscrowManager:", escrowManager.address);
    console.log("DocumentVerification:", documentVerification.address);
    console.log("Network:", network);
    console.log("Gas used for deployment: Check transaction receipts");
    console.log("=====================================\n");

    // Save deployment info to a file for frontend use
    const fs = require('fs');
    const deploymentInfo = {
      network: network,
      contracts: {
        LandRegistry: {
          address: landRegistry.address,
          abi: LandRegistry.abi
        },
        EscrowManager: {
          address: escrowManager.address,
          abi: EscrowManager.abi
        },
        DocumentVerification: {
          address: documentVerification.address,
          abi: DocumentVerification.abi
        }
      },
      deployedAt: new Date().toISOString(),
      deployer: accounts[0]
    };

    // Create build directory if it doesn't exist
    if (!fs.existsSync('./build')) {
      fs.mkdirSync('./build');
    }

    fs.writeFileSync(
      `./build/deployment-${network}.json`,
      JSON.stringify(deploymentInfo, null, 2)
    );
    console.log(`Deployment info saved to ./build/deployment-${network}.json`);

  } catch (error) {
    console.error("Deployment failed:", error);
    throw error;
  }
};