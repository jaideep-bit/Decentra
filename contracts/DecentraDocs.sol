? Constructor now initializes Ownable with msg.sender


    constructor() Ownable(msg.sender) {}

    function createDocument(
        string memory documentHash,
        address[] memory requiredSigners
    ) external payable nonReentrant {
        require(msg.value >= storageFee, "Insufficient storage fee");
        require(bytes(documentHash).length > 0, "Document hash cannot be empty");
        require(requiredSigners.length > 0, "At least one signer required");
        
        documentCounter++;
        Document storage newDoc = documents[documentCounter];
        newDoc.documentHash = documentHash;
        newDoc.creator = msg.sender;
        newDoc.createdAt = block.timestamp;
        newDoc.isActive = true;
        newDoc.requiredSigners = requiredSigners;
        newDoc.signatureCount = 0;
        newDoc.isCompleted = false;
        
        userDocuments[msg.sender].push(documentCounter);
        
        for (uint256 i = 0; i < requiredSigners.length; i++) {
            signerDocuments[requiredSigners[i]].push(documentCounter);
        }
        
        emit DocumentCreated(documentCounter, msg.sender, documentHash);
    }


    
    function signDocument(uint256 documentId) external nonReentrant {
        Document storage doc = documents[documentId];
        require(doc.isActive, "Document is not active");
        require(!doc.isCompleted, "Document already completed");
        require(!doc.signatures[msg.sender], "Already signed");
        require(isRequiredSigner(documentId, msg.sender), "Not authorized to sign");
        
        doc.signatures[msg.sender] = true;
        doc.signatureCount++;
        
        emit DocumentSigned(documentId, msg.sender);
        
        if (doc.signatureCount == doc.requiredSigners.length) {
            doc.isCompleted = true;
            emit DocumentCompleted(documentId);
        }
    }
    
    function revokeDocument(uint256 documentId) external {
        Document storage doc = documents[documentId];
        require(doc.creator == msg.sender, "Only creator can revoke");
        require(doc.isActive, "Document already inactive");
        require(!doc.isCompleted, "Cannot revoke completed document");
        
        doc.isActive = false;
        
        emit DocumentRevoked(documentId);
    }
    
    function getDocumentDetails(uint256 documentId) external view returns (DocumentView memory) {
        Document storage doc = documents[documentId];
        return DocumentView({
            documentHash: doc.documentHash,
            creator: doc.creator,
            createdAt: doc.createdAt,
            isActive: doc.isActive,
            requiredSigners: doc.requiredSigners,
            signatureCount: doc.signatureCount,
            isCompleted: doc.isCompleted
        });
    }
    
    function hasUserSigned(uint256 documentId, address user) external view returns (bool) {
        return documents[documentId].signatures[user];
    }
    
    function isRequiredSigner(uint256 documentId, address user) public view returns (bool) {
        Document storage doc = documents[documentId];
        for (uint256 i = 0; i < doc.requiredSigners.length; i++) {
            if (doc.requiredSigners[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function getUserDocuments(address user) external view returns (uint256[] memory) {
        return userDocuments[user];
    }
    
    function getSignerDocuments(address signer) external view returns (uint256[] memory) {
        return signerDocuments[signer];
    }
    
    function setStorageFee(uint256 _newFee) external onlyOwner {
        storageFee = _newFee;
    }
    
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
// 
End
// 
