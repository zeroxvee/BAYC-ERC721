// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DutchAuction.sol";
import "./Bayc.sol";
import "./Bacc.sol";

/**
 * @title MAYC contract recreated for learning/testing purposes
 * @dev Implementation MAYC contract by using interfaces only
 */
contract SuperFakeMutantApeYachtClub is IERC721, IERC721Metadata, Ownable, ReentrancyGuard, DutchAuction {

    using Strings for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    string private _uri;

    // Two types of mutants: M1 and M2
    uint256 private constant NUM_MUTANT_TYPES = 2;
    // Serum mutations id start minted mutants + 10000
    uint256 public constant SERUM_MUTATION_OFFSET = 10_000;
    // Max amount of mega mutants possible
    uint256 public constant NUM_MEGA_MUTANTS = 8;
    // Id for mega mutation
    uint256 private constant MEGA_MUTATION_TYPE = 69;
    // Last if of mega mutation
    uint256 private constant MAX_MEGA_MUTATION_ID = 30_007;
    // Total possible count of apes to be minted
    uint256 private constant TOTAL_MINT_SUPPLY = 10_000;
    // Max to mint per tx
    uint256 private constant MAX_PER_MINT = 20;
    // Count of apes minted
    uint256 private mutantsMintCount;
    // Count of apes mutated
    uint256 private mutationsCount;

    // Mega mutants IDs start from 30000
    uint256 private currentMegaMutationId = 30_000;
    mapping(uint256 => uint256) private megaMutationIdsByApe;

    bool public isSerumMutationActive;

    // Mapping for all owners who own apes
    mapping(uint256 => address) private _owners;
    // Amount of apes owned for each owner
    mapping(address => uint256) private _balances;
    // Transfer approvals for # token
    mapping(uint256 => address) private _tokenApprovals;
    // approved operators for owner of # token
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    Bayc private immutable bayc;
    Bacc private immutable bacc;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri,
        address baycAddress,
        address baccAddress
        ) {
        _name = name_;
        _symbol = symbol_;
        _uri = uri;
        bayc = Bayc(baycAddress);
        bacc = Bacc(baccAddress);
    }

    event StartingIndicesSet(
        uint256 indexed _mintedMutantsStartingIndex,
        uint256 indexed _megaMutantsStartingIndex
    );

    /**
     * @notice returns name of the collection
     * @return _name string
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @notice returns symbol of the collection
     * @return _symbol string
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice calculates URI for each token
     * @return URI as string
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exists");

        return bytes(_uri).length > 0 ?
        string(abi.encodePacked(_uri, tokenId.toString())) : ""; 
    }

    /**
     * @notice checks the amount of tokens owned by address
     * @param owner an address to check
     * @return balance as token owned
     */
    function balanceOf(address owner) external view override returns (uint256 balance) {
        require(_balances[owner] > 0, "0 balance");

        return _balances[owner];
    }

    /**
     * @notice check if existing token is owned
     * @param tokenId token #
     * @return owner address who owns the token
     */
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        require(_exists(tokenId), "Token doesn't exists");

        return _owners[tokenId];
    }

    /**
     * @notice checks conditions for transfer approval
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     */
    function approve(address to, uint256 tokenId) external {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "Not owner nor approved");

        _approve(owner, to, tokenId);
    }

    /**
     * @notice approves token for transfer and emits an event
     * @param owner address of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     */
    function _approve(address owner, address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice checks if token has any transfer approved
     * @param tokenId token to check for approvals
     * @return operator address that is approved for token #
     */
    function getApproved(uint256 tokenId) external view returns (address operator) {
        require(_exists(tokenId), "Token doesn't exists");

        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Sets an approved operator for all token transfers
     * @param operator address of operator to appprove by owner of token
     * @param approved state of approval for operator address
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "Attempt to approve the fx caller");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice checks if address has approved operators
     * @param owner address of token
     * @param operator address
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice transfer the token from to new owner
     * @param from current owner of token
     * @param to address to transfer to
     * @param tokenId current token # for transfer
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        address owner = _owners[tokenId];
        require(from == owner, "Transfer from not owner address");
        require(to != address(0), "Attempt to send to 0 address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        _approve(owner, address(0), tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @notice checks for transfer conditions
     * @param from address of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, to, tokenId), "Not approved nor owner");

        _transfer(from, to, tokenId);
    }

    /**
     * @notice transfers token from owner to address
     * @param from owner of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     * @param _data calldata to transfer if receiver is contract
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "transfer to non ERC721Receiver");
    }

    /**
     * @notice Transfer token from owner to new owner if caller is EOA
     * @param from owner of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function totalApesMutated() external view returns (uint256) {
        return mutationsCount;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        _uri = uri_;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(
            tokenId < MAX_MEGA_MUTATION_ID,
            "tokenId outside collection bounds"
        );
        return _exists(tokenId);
    }

    function toggleSerumMutationState() external onlyOwner {
        isSerumMutationActive = !isSerumMutationActive;
    }

    /**
     * @notice Transfer token from owner to new owner if caller is a another
     * smart contract
     * @param from owner of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(_isApprovedOrOwner(msg.sender, to, tokenId), "Not approved nor owner");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @notice Check if "to" is a contract
     * @param from owner of token
     * @param to token receiver
     * @param tokenId current token # to approve for transfer
     * @param _data calldata to transfer if receiver is contract
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    /**
     * @notice Minting of new ape nfts
     * @param amount of tokens to mint in one Tx
     */
    function mintMutantApes(uint256 amount) public payable whenSaleIsActive() {
        require(
            amount <= MAX_PER_MINT && amount > 0,
            "Amount to mint has to be from 1 to 20"
        );
        require(
            mutantsMintCount + amount <= TOTAL_MINT_SUPPLY,
            "Mint would exceed total supply"
        );
        uint256 price = getPrice();
        require(msg.value >= price * amount, "Not enough ether to mint");

        for(uint i = 0; i < amount; i++) {
            _mint(msg.sender, mutantsMintCount);
            mutantsMintCount += 1;
        }

        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function mutateApeWithSerum(uint256 serumTypeId, uint256 apeId)
        external
        nonReentrant
    {
        require(isSerumMutationActive, "Serum Mutation is not active");
        require(
            bayc.ownerOf(apeId) == msg.sender,
            "Must own the ape you're attempting to mutate"
        );
        require(
            bacc.balanceOf(msg.sender, serumTypeId) > 0,
            "Must own at least one of this serum type to mutate"
        );

        uint256 mutantId;

        if (serumTypeId == MEGA_MUTATION_TYPE) {
            require(
                currentMegaMutationId <= MAX_MEGA_MUTATION_ID,
                "Would exceed supply of serum-mutatable MEGA MUTANTS"
            );
            require(
                megaMutationIdsByApe[apeId] == 0,
                "Ape already mutated with MEGA MUTATION SERUM"
            );

            mutantId = currentMegaMutationId;
            megaMutationIdsByApe[apeId] = mutantId;
            currentMegaMutationId++;
        } else {
            mutantId = getMutantId(serumTypeId, apeId);
            require(
                !_exists(mutantId),
                "Ape already mutated with this type of serum"
            );
        }

        mutationsCount++;
        bacc.burnSerumForAddress(serumTypeId, msg.sender);
        _safeMint(msg.sender, mutantId);
    }

    function getMutantIdForApeAndSerumCombination(
        uint256 apeId,
        uint8 serumTypeId
    ) external view returns (uint256) {
        uint256 mutantId;
        if (serumTypeId == MEGA_MUTATION_TYPE) {
            mutantId = megaMutationIdsByApe[apeId];
            require(mutantId > 0, "Invalid MEGA Mutant Id");
        } else {
            mutantId = getMutantId(serumTypeId, apeId);
        }

        require(_exists(mutantId), "Query for nonexistent mutant");

        return mutantId;
    }

    function getMutantId(uint256 serumType, uint256 apeId)
        internal
        pure
        returns (uint256)
    {
        require(
            serumType != MEGA_MUTATION_TYPE,
            "Mega mutant ID can't be calculated"
        );
        return (apeId * NUM_MUTANT_TYPES) + serumType + SERUM_MUTATION_OFFSET;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @notice Assigns new token to and address
     * @param to function caller address
     * @param tokenId number to be minted
     */
    function _mint (address to, uint256 tokenId) internal {
        require(!_exists(tokenId), "Token already exists");
        require(to != address(0), "Mint to 0 address");

        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;

        emit Transfer(address(0), msg.sender, tokenId);
    }

    // Checks if token has an owner assigned
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Sends all ether from contract to owner
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice Checks if token allowed to be transfered
     * @param owner owner of token
     * @param spender transfer function caller
     * @param tokenId current token # to for transfer
     * @return true of false whether all conditions apply
     */
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        require(_exists(tokenId), "Token doesn't exists");

        return _owners[tokenId] == owner ||
        spender == _tokenApprovals[tokenId] ||
        _operatorApprovals[owner][spender];
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}