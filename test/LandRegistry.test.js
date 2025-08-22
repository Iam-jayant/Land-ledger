const LandRegistry = artifacts.require("LandRegistry");
const EscrowManager = artifacts.require("EscrowManager");
const DocumentVerification = artifacts.require("DocumentVerification");

contract("LandRegistry", (accounts) => {
  let landRegistry;
  let escrowManager;
  let documentVerification;
  
  const [admin, inspector, seller, buyer, publicUser] = accounts;

  beforeEach(async () => {
    landRegistry = await LandRegistry.new();
    escrowManager = await EscrowManager.new();
    documentVerification = await DocumentVerification.new();
  });

  describe("Contract Deployment", () => {
    it("should deploy LandRegistry successfully", async () => {
      assert(landRegistry.address !== "");
      console.log("LandRegistry deployed at:", landRegistry.address);
    });

    it("should deploy EscrowManager successfully", async () => {
      assert(escrowManager.address !== "");
      console.log("EscrowManager deployed at:", escrowManager.address);
    });

    it("should deploy DocumentVerification successfully", async () => {
      assert(documentVerification.address !== "");
      console.log("DocumentVerification deployed at:", documentVerification.address);
    });
  });

  describe("User Registration", () => {
    it("should register a seller successfully", async () => {
      const tx = await landRegistry.registerSeller(
        "Manthan Kumar",
        30,
        "Mumbai",
        "123456789012", // Aadhar
        "ABCDE1234F",   // PAN
        "manthan@example.com",
        "QmTestDocumentHash123",
        { from: seller }
      );

      assert(tx.receipt.status === true);
      
      // Check if seller is registered
      const isRegistered = await landRegistry.isRegisteredSeller(seller);
      assert(isRegistered === true);

      console.log("Seller registered successfully:", seller);
    });

    it("should register a buyer successfully", async () => {
      const tx = await landRegistry.registerBuyer(
        "Ved Sharma",
        25,
        "Delhi",
        "987654321098", // Aadhar
        "FGHIJ5678K",   // PAN
        "ved@example.com",
        "QmTestBuyerDocHash456",
        { from: buyer }
      );

      assert(tx.receipt.status === true);
      
      // Check if buyer is registered
      const isRegistered = await landRegistry.isRegisteredBuyer(buyer);
      assert(isRegistered === true);

      console.log("Buyer registered successfully:", buyer);
    });
  });

  describe("Inspector Functions", () => {
    beforeEach(async () => {
      // Register seller and buyer first
      await landRegistry.registerSeller(
        "Manthan Kumar",
        30,
        "Mumbai",
        "123456789012",
        "ABCDE1234F",
        "manthan@example.com",
        "QmTestDocumentHash123",
        { from: seller }
      );

      await landRegistry.registerBuyer(
        "Ved Sharma",
        25,
        "Delhi",
        "987654321098",
        "FGHIJ5678K",
        "ved@example.com",
        "QmTestBuyerDocHash456",
        { from: buyer }
      );
    });

    it("should verify seller by inspector", async () => {
      const tx = await landRegistry.verifySeller(seller, true, { from: admin });
      assert(tx.receipt.status === true);

      // Check if seller is verified
      const isVerified = await landRegistry.isUserVerified(seller);
      assert(isVerified === true);

      console.log("Seller verified successfully");
    });

    it("should verify buyer by inspector", async () => {
      const tx = await landRegistry.verifyBuyer(buyer, true, { from: admin });
      assert(tx.receipt.status === true);

      // Check if buyer is verified
      const isVerified = await landRegistry.isUserVerified(buyer);
      assert(isVerified === true);

      console.log("Buyer verified successfully");
    });
  });

  describe("Property Management", () => {
    beforeEach(async () => {
      // Register and verify seller
      await landRegistry.registerSeller(
        "Manthan Kumar",
        30,
        "Mumbai",
        "123456789012",
        "ABCDE1234F",
        "manthan@example.com",
        "QmTestDocumentHash123",
        { from: seller }
      );
      await landRegistry.verifySeller(seller, true, { from: admin });
    });

    it("should list property by verified seller", async () => {
      const tx = await landRegistry.listProperty(
        1000, // area in sq ft
        "Mumbai",
        "Maharashtra",
        web3.utils.toWei("10", "ether"), // price in wei
        "MH12345678901234", // ULPIN
        123, // survey number
        "QmPropertyDocHash789",
        "QmPropertyImageHash101",
        { from: seller }
      );

      assert(tx.receipt.status === true);
      
      // Get total properties
      const totalProperties = await landRegistry.getTotalProperties();
      assert(totalProperties.toNumber() === 1);

      console.log("Property listed successfully");
    });

    it("should verify property by inspector", async () => {
      // List property first
      await landRegistry.listProperty(
        1000,
        "Mumbai",
        "Maharashtra",
        web3.utils.toWei("10", "ether"),
        "MH12345678901234",
        123,
        "QmPropertyDocHash789",
        "QmPropertyImageHash101",
        { from: seller }
      );

      // Verify property
      const tx = await landRegistry.verifyProperty(1, true, { from: admin });
      assert(tx.receipt.status === true);

      // Check if property is verified
      const isVerified = await landRegistry.isPropertyVerified(1);
      assert(isVerified === true);

      console.log("Property verified successfully");
    });
  });

  describe("Document Verification Contract", () => {
    it("should upload document successfully", async () => {
      const tx = await documentVerification.uploadDocument(
        "QmTestDocumentHash123",
        "property_deed.pdf",
        0, // PropertyDeed type
        "Property deed for Mumbai land",
        web3.utils.keccak256("test content"),
        false, // not public
        { from: seller }
      );

      assert(tx.receipt.status === true);
      
      const totalDocs = await documentVerification.getTotalDocuments();
      assert(totalDocs.toNumber() === 1);

      console.log("Document uploaded successfully");
    });
  });

  describe("Integration Test", () => {
    it("should complete full property transaction flow", async () => {
      console.log("=== Starting Full Transaction Flow ===");

      // Step 1: Register users
      console.log("1. Registering seller and buyer...");
      await landRegistry.registerSeller(
        "Manthan Kumar",
        30,
        "Mumbai",
        "123456789012",
        "ABCDE1234F",
        "manthan@example.com",
        "QmTestDocumentHash123",
        { from: seller }
      );

      await landRegistry.registerBuyer(
        "Ved Sharma",
        25,
        "Delhi",
        "987654321098",
        "FGHIJ5678K",
        "ved@example.com",
        "QmTestBuyerDocHash456",
        { from: buyer }
      );

      // Step 2: Verify users
      console.log("2. Verifying users...");
      await landRegistry.verifySeller(seller, true, { from: admin });
      await landRegistry.verifyBuyer(buyer, true, { from: admin });

      // Step 3: List property
      console.log("3. Listing property...");
      await landRegistry.listProperty(
        1000,
        "Mumbai",
        "Maharashtra",
        web3.utils.toWei("10", "ether"),
        "MH12345678901234",
        123,
        "QmPropertyDocHash789",
        "QmPropertyImageHash101",
        { from: seller }
      );

      // Step 4: Verify property
      console.log("4. Verifying property...");
      await landRegistry.verifyProperty(1, true, { from: admin });

      // Step 5: Request purchase
      console.log("5. Requesting purchase...");
      const purchaseTx = await landRegistry.requestPurchase(
        1, // property ID
        web3.utils.toWei("10", "ether"), // offer price
        { from: buyer }
      );

      // Step 6: Approve purchase request
      console.log("6. Approving purchase request...");
      await landRegistry.approvePurchaseRequest(1, { from: seller });

      // Step 7: Make payment
      console.log("7. Making payment...");
      await landRegistry.makePayment(1, {
        from: buyer,
        value: web3.utils.toWei("10", "ether")
      });

      // Step 8: Approve ownership transfer
      console.log("8. Approving ownership transfer...");
      await landRegistry.approveOwnershipTransfer(1, { from: admin });

      // Verify final state
      const newOwner = await landRegistry.getPropertyOwner(1);
      assert(newOwner === buyer);

      console.log("=== Transaction Flow Completed Successfully! ===");
      console.log("Property ownership transferred from", seller, "to", buyer);
    });
  });
});