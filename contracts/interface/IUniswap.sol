pragma solidity ^0.8.0;
interface IUniswapV2{
struct Pair{
    address token0;
    address token1;
}
 function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

}