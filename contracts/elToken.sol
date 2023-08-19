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


	elToken.sol

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

contract elToken {
	string public name;
	string public symbol;
	uint8  public decimals = 18;
	uint256  public totalSupply;
	mapping(address=>uint256) public balanceOf;
	mapping(address=>mapping(address=>uint256)) public allowance;
	address public dao;
	address public minter;
	mapping(address=>bool) public minters;
	event  Approval(address indexed o, address indexed s, uint a);
	event  Transfer(address indexed s, address indexed d, uint a);
	modifier DAO() {
		require(msg.sender==dao, "Unknown!");
		_;
	}
	modifier MINTERS() {
		require(msg.sender==minter || minters[msg.sender], "Unauthorized!");
		_;
	}
	function approve(address s, uint a) public returns (bool) {
		allowance[msg.sender][s] = a;
		emit Approval(msg.sender, s, a);
		return true;
	}
	function transfer(address d, uint a) public returns (bool) {
		return transferFrom(msg.sender, d, a);
	}
	function transferFrom(address s, address d, uint a) public returns (bool) {
		require(balanceOf[s] >= a, "Insufficient");
		if (s != msg.sender && allowance[s][msg.sender] != type(uint256).max) {
			require(allowance[s][msg.sender] >= a, "Not allowed!");
			allowance[s][msg.sender] -= a;
		}
		balanceOf[s] -= a;
		balanceOf[d] += a;
		emit Transfer(s, d, a);
		return true;
	}
	function mint(uint256 a, address w) public MINTERS returns (bool) {
		totalSupply+=a;
		balanceOf[w]+=a;
		emit Transfer(address(0), w, a);
		return true;
	}
	function burn(uint256 a) public returns (bool) {
		require(balanceOf[msg.sender]>=a, "Insufficient");
		totalSupply-=a;
		balanceOf[msg.sender]-=a;
		emit Transfer(msg.sender, address(0), a);
		return true;
	}
	function setMinter(address m) public DAO {
		minter = m;
	}
	function setMinters(address m, bool b) public DAO {
		minters[m] = b;
	}
	function setDAO(address d) public DAO {
		dao = d;
	}
	constructor(string memory _n, string memory _s) {
		dao=msg.sender;
		name = _n;
		symbol = _s;
	}
}

/*
	Community, Services & Enquiries:
		https://discord.gg/QpyfMarNrV

	Powered by Guru Network DAO ( 🦾 , 🚀 )
		Simplicity is the ultimate sophistication.
*/