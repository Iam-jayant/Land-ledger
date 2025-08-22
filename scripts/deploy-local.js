const LandRegistry = artifacts.require("LandRegistry");
const EscrowManager = artifacts.require("EscrowManager");
const DocumentVerification = artifacts.require("DocumentVerification");

module.exports = async function (callback) {
    try {
        console.log("🚀 Starting LandLedger Local Deployment...\n");

        const accounts = await web3.eth.getAccounts();
        console.log("Available accounts:", accounts.length);
        console.log("Deployer account:", accounts[0]);
        console.log("Inspector account:", accounts[1]);
        console.log("Seller account:", accounts[2]);
        console.log("Buyer account:", accounts[3]);
        console.log();

        // Deploy contracts
        console.log("📄 Deploying contracts...");
        const landRegistry = await LandRegistry.deployed();
        const escrowManager = await EscrowManager.deployed();
        const documentVerification = await DocumentVerification.deployed();

        console.log("✅ LandRegistry deployed at:", landRegistry.address);
        console.log("✅ EscrowManager deployed at:", escrowManager.address);
        console.log("✅ DocumentVerification deployed at:", documentVerification.address);
        console.log();

        // Setup demo data
        console.log("🎭 Setting up demo data...");

        const [admin, inspector, seller, buyer] = accounts;

        // Register demo seller
        console.log("👤 Registering demo seller...");
        await landRegistry.registerSeller(
            "Manthan Kumar",
            30,
            "Mumbai",
            "123456789012",
            "ABCDE1234F",
            "manthan@landledger.io",
            "QmDemoSellerDoc123",
            { from: seller }
        );

        // Register demo buyer
        console.log("👤 Registering demo buyer...");
        await landRegistry.registerBuyer(
            "Ved Sharma",
            25,
            "Delhi",
            "987654321098",
            "FGHIJ5678K",
            "ved@landledger.io",
            "QmDemoBuyerDoc456",
            { from: buyer }
        );

        // Verify users
        console.log("✅ Verifying demo users...");
        await landRegistry.verifySeller(seller, true, { from: admin });
        await landRegistry.verifyBuyer(buyer, true, { from: admin });

        // List demo property
        console.log("🏠 Listing demo property...");
        await landRegistry.listProperty(
            1500, // 1500 sq ft
            "Mumbai",
            "Maharashtra",
            web3.utils.toWei("15", "ether"), // 15 ETH
            "MH12345678901234",
            123,
            "QmDemoPropertyDoc789",
            "QmDemoPropertyImg101",
            { from: seller }
        );

        // Verify property
        console.log("✅ Verifying demo property...");
        await landRegistry.verifyProperty(1, true, { from: admin });

        console.log("\n🎉 LandLedger setup complete!");
        console.log("\n📊 Summary:");
        console.log("- Contracts deployed and configured");
        console.log("- Demo seller and buyer registered and verified");
        console.log("- Demo property listed and verified");
        console.log("- Ready for testing purchase flow!");

        console.log("\n🔗 Contract Addresses:");
        console.log("LandRegistry:", landRegistry.address);
        console.log("EscrowManager:", escrowManager.address);
        console.log("DocumentVerification:", documentVerification.address);

        console.log("\n👥 Demo Accounts:");
        console.log("Admin/Inspector:", admin);
        console.log("Seller (Manthan):", seller);
        console.log("Buyer (Ved):", buyer);

        console.log("\n🚀 Next Steps:");
        console.log("1. Start your frontend application");
        console.log("2. Connect MetaMask to http://localhost:7545");
        console.log("3. Import the demo accounts using their private keys");
        console.log("4. Test the complete property transaction flow!");

        callback();
    } catch (error) {
        console.error("❌ Deployment failed:", error);
        callback(error);
    }
};