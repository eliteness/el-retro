/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU



						Contact us at:
			https://discord.com/invite/QpyfMarNrV
					https://t.me/FTM1337

	Community Mediums:
		https://medium.com/@ftm1337
		https://twitter.com/ftm1337

	SPDX-License-Identifier: UNLICENSED


	elToken_Depositor.sol

	elToken is a Liquid Staking Derivate for veTokens (Vote-Escrowed NFT).
	It can be minted by merging a user's veNFT into the Protocol's veNFT.
	elTokens are ERC20 based tokens.
	It can be staked with Guru Network to earn pure Real Yield,
	paid in a single prominent token such as ETH or BNB instead of multiple small tokens.
	elTokens can be further deposited into other De-Fi Protocols for even more utilities!

	The price (in Base Token) to mint an elToken goes up every epoch due to positive rebasing.
	This property gives elTokens a "hyper-compounding" exponential trajectory against base tokens,
	and it helps elTokens have a true inflation-resistant future!

*/

pragma solidity 0.8.9;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function transfer(address recipient, uint amount) external returns (bool);
	function balanceOf(address) external view returns (uint);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}
interface IelToken is IERC20 {
	function mint(uint a, address w) external returns (bool);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IVotingEscrow {
	struct LockedBalance {
		int128 amount;
		uint end;
	}
	function create_lock_for(uint _value, uint _lock_duration, address _to) external returns (uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function locked(uint id) external view returns(LockedBalance memory);
	function token() external view returns (address);
	function merge(uint _from, uint _to) external;
}

contract elToken_Depositor {
	struct LockedBalance {
		int128 amount;
		uint end;
	}
	address public dao;
	IelToken public elToken;
	IVotingEscrow public veToken;
	uint public ID;
	uint public supplied;
	uint public converted;
	uint public minted;
	/// @notice ftm.guru simple re-entrancy check
	bool internal _locked;
	modifier lock() {
		require(!_locked,  "Re-entry!");
		_locked = true;
		_;
		_locked = false;
	}
	modifier DAO() {
		require(msg.sender==dao, "Unauthorized!");
		_;
	}
	event Deposit(address indexed, uint indexed, uint, uint, uint);
    function onERC721Received(address, address,  uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(veToken), "!veToken");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
	function deposit(uint _id) public lock returns (uint) {
		uint _ts = elToken.totalSupply();
		IVotingEscrow.LockedBalance memory _main = veToken.locked(ID);
		require(_main.amount > 0, "Dirty veNFT!");
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		veToken.safeTransferFrom(msg.sender, address(this), _id);	//important (bug)fix!
		veToken.merge(_id,ID);
		IVotingEscrow.LockedBalance memory _merged = veToken.locked(ID);
		int _in = _merged.amount - _main.amount;
		require(_in > 0, "Dirty Deposit!");
		uint256 _inc = uint256(_in);//cast to uint
		supplied += _inc;
		converted++;
		// If no elToken exists, mint it 1:1 to the amount of Base Token present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			elToken.mint(_inc, msg.sender);
			emit Deposit(msg.sender, _id, _inc, _inc, block.timestamp);
			minted+=_inc;
			return _inc;
		}
		// Calculate and mint the amount of elToken the veNFT is worth. The ratio will change overtime,
		// as elToken is minted when veToken are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			elToken.mint(_amt, msg.sender);
			emit Deposit(msg.sender, _id, _inc, _amt, block.timestamp);
			minted+=_amt;
			return _amt;
		}
	}
	function initialize(uint _id) public DAO lock {
		IVotingEscrow.LockedBalance memory _main = veToken.locked(_id);
		require(_main.amount > 0, "Dirty veNFT!");
		int _iamt = _main.amount;
		uint _amt = uint(_iamt);
		elToken.mint(_amt, msg.sender);
		ID = _id;
		supplied += _amt;
		converted++;
		minted+=_amt;
	}
	function quote(uint _id) public view returns (uint) {
		uint _ts = elToken.totalSupply();
		IVotingEscrow.LockedBalance memory _main = veToken.locked(ID);
		IVotingEscrow.LockedBalance memory _user = veToken.locked(_id);
		if( ! (_main.amount > 0) ) {return 0;}
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		int _in = _user.amount;
		if( ! (_in > 0) ) {return 0;}
		uint256 _inc = uint256(_in);//cast to uint
		// If no elToken exists, mint it 1:1 to the amount of Base Token present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			return _inc;
		}
		// Calculate and mint the amount of elToken the veNFT is worth. The ratio will change overtime,
		// as elToken is minted when veToken are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			return _amt;
		}
	}
	function rawQuote(uint _inc) public view returns (uint) {
		uint _ts = elToken.totalSupply();
		IVotingEscrow.LockedBalance memory _main = veToken.locked(ID);
		if( ! (_main.amount > 0) ) {return 0;}
		int _ibase = _main.amount;	//pre-cast to int
		uint256 _base = uint256(_ibase);
		// If no elToken exists, mint it 1:1 to the amount of Base Token present inside the veNFT deposited
		if (_ts == 0 || _base == 0) {
			return _inc;
		}
		// Calculate and mint the amount of elToken the veNFT is worth. The ratio will change overtime,
		// as elToken is minted when veToken are deposited + gained from rebases
		else {
			uint256 _amt = (_inc * _ts) / _base;
			return _amt;
		}
	}
	function price() public view returns (uint) {
		return 1e36 / rawQuote(1e18);
	}
	function setDAO(address d) public DAO {
		dao = d;
	}
	function setID(uint _id) public DAO {
		ID = _id;
	}
	function rescue(address _t, uint _a) public DAO lock {
		IERC20 _tk = IERC20(_t);
		_tk.transfer(dao, _a);
	}
	constructor(address ve, address e) {
		dao=msg.sender;
		veToken = IVotingEscrow(ve);
		elToken = IelToken(e);
	}
}

/*
	Community, Services & Enquiries:
		https://discord.gg/QpyfMarNrV

	Powered by Guru Network DAO ( 🦾 , 🚀 )
		Simplicity is the ultimate sophistication.
*/