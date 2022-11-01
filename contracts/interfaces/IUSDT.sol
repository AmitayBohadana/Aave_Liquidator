import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUSDT is IERC20 {
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;

    function issue(uint256) external;
    function mint(address _to,uint256 _amount) external returns (bool);
}