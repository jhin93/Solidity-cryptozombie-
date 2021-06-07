// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./ownable.sol";

// 접근 제어자(visibility modifier) : public, private, internal, external
// 상태 제어자(state modifier) : view, pure
// 함수 제어자 : 'modifier' - lesson3 챕터 3 참고.

// 챕터 4: 가스(Gas)

// 훌륭해! 이제 우리는 사용자들이 우리 컨트랙트를 마구 휘젓지 못하게 하면서도 DApp의 핵심적인 부분을 업데이트할 수 있는 방법을 터득했네.
// 지금부터는 또 다른 솔리디티와 다른 프로그래밍 언어들의 차이점을 살펴볼 것이네.

// 직접 해보기

// 이번 레슨에서는, 우리는 우리의 좀비에게 2개의 새로운 특징을 추가할 것이네. level과 readyTime이지. 
// readyTime은 좀비가 먹이를 먹는 빈도를 제한할 재사용 대기 시간을 구현하기 위해 사용하네.

// 자, 그럼 다시 zombiefactory.sol으로 돌아가지.

// 1. 우리의 Zombie 구조체에 2개의 속성을 더 추가하게: level(uint32)과 readyTime(마찬가지로 uint32)를 말이지. 우리는 이 데이터 타입들을 압축하길 원하니, 이 둘을 구조체의 마지막 부분에 쓰게.

// 좀비의 레벨과 시간 데이터(Timestamp)를 저장하는 데에는 충분하고도 남는 크기이니, 이렇게 하면 보통의 uint(256비트)를 쓰는 것보다 데이터를 더 압축해서 가스 비용을 줄이도록 해줄 것이네.

contract ZombieFactory is Ownable{
    event NewZombie(uint zombieId, string name, uint dna);
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Zombie {
        string name;
        uint dna;
        // 여기 새 데이터를 입력하게
        uint32 level;
        uint32 readyTime;
    }

    Zombie[] public zombies;
    mapping (uint => address) public zombieToOwner;
    mapping (address => uint) ownerZombieCount;

    function _createZombie(string memory _name, uint _dna) internal {
        // 아랫줄 오류발생. Wrong argument count for struct constructor: 2 arguments given but expected 4.
        zombies.push(Zombie(_name, _dna));
        uint id = zombies.length - 1;
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender] ++;
        emit NewZombie(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomZombie(string memory _name) public {
        require(ownerZombieCount[msg.sender] == 0);
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

}

// 가스 - 이더리움 DApp이 사용하는 연료

// 솔리디티에서는 사용자들이 자네가 만든 DApp의 함수를 실행할 때마다 _가스_라고 불리는 화폐를 지불해야 하네. 
// 사용자는 이더(ETH, 이더리움의 화폐)를 이용해서 가스를 사기 때문에, 자네의 DApp 함수를 실행하려면 사용자들은 ETH를 소모해야만 하네.

// 함수를 실행하는 데에 얼마나 많은 가스가 필요한지는 그 함수의 로직(논리 구조)이 얼마나 복잡한지에 따라 달라지네. 
// 각각의 연산은 소모되는 가스 비용(gas cost)이 있고, 그 연산을 수행하는 데에 소모되는 컴퓨팅 자원의 양이 이 비용을 결정하네. 
// 예를 들어, storage에 값을 쓰는 것은 두 개의 정수를 더하는 것보다 훨씬 비용이 높네. 
// 자네 함수의 전체 가스 비용은 그 함수를 구성하는 개별 연산들의 가스 비용을 모두 합친 것과 같네.

// 함수를 실행하는 것은 자네의 사용자들에게 실제 돈을 쓰게 하기 때문에, 이더리움에서 코드 최적화는 다른 프로그래밍 언어들에 비해 훨씬 더 중요하네. 
// 만약 자네의 코드가 엉망이라면, 사용자들은 자네의 함수를 실행하기 위해 일종의 할증료를 더 내야 할 걸세. 
// 그리고 수천 명의 사용자가 이런 불필요한 비용을 낸다면 할증료가 수십 억 원까지 쌓일 수 있지.

// 가스는 왜 필요한가?

// 이더리움은 크고 느린, 하지만 굉장히 안전한 컴퓨터와 같다고 할 수 있네. 
// 자네가 어떤 함수를 실행할 때, 네트워크상의 모든 개별 노드가 함수의 출력값을 검증하기 위해 그 함수를 실행해야 하지. 
// 모든 함수의 실행을 검증하는 수천 개의 노드가 바로 이더리움을 분산화하고, 데이터를 보존하며 누군가 검열할 수 없도록 하는 요소이지.

// 이더리움을 만든 사람들은 누군가가 무한 반복문을 써서 네트워크를 방해하거나, 자원 소모가 큰 연산을 써서 네트워크 자원을 모두 사용하지 못하도록 만들길 원했다네. 
// 그래서 그들은 연산 처리에 비용이 들도록 만들었고, 사용자들은 저장 공간 뿐만 아니라 연산 사용 시간에 따라서도 비용을 지불해야 한다네.

// 참고: 사이드체인에서는 반드시 이렇지는 않다네. 크립토좀비를 만든 사람들이 Loom Network에서 만들고 있는 것들이 좋은 예시가 되겠군. 
// 이더리움 메인넷에서 월드 오브 워크래프트 같은 게임을 직접적으로 돌리는 것은 절대 말이 되지 않을 걸세. 
// 가스 비용이 엄청나게 높을 것이기 때문이지. 하지만 다른 합의 알고리즘을 가진 사이드체인에서는 가능할 수 있지. 
// 우린 다음에 나올 레슨에서 DApp을 사이드체인에 올릴지, 이더리움 메인넷에 올릴지 판단하는 방법들에 대해 더 얘기할 걸세.

// 가스를 아끼기 위한 구조체 압축

// 레슨 1에서, 우리는 uint에 다른 타입들이 있다는 것을 배웠지. uint8, uint16, uint32, 기타 등등..
// 기본적으로는 이런 하위 타입들을 쓰는 것은 아무런 이득이 없네. 왜냐하면 솔리디티에서는 uint의 크기에 상관없이 256비트의 저장 공간을 미리 잡아놓기 때문이지. 
// 예를 들자면, uint(uint256) 대신에 uint8을 쓰는 것은 가스 소모를 줄이는 데에 아무 영향이 없네.

// 하지만 여기에 예외가 하나 있지. 바로 struct의 안에서라네.

// 만약 자네가 구조체 안에 여러 개의 uint를 만든다면, 가능한 더 작은 크기의 uint를 쓰도록 하게. 
// 솔리디티에서 그 변수들을 더 적은 공간을 차지하도록 압축할 것이네. 예를 들면 다음과 같지:

// struct NormalStruct {
//   uint a;
//   uint b;
//   uint c;
// }

// struct MiniMe {
//   uint32 a;
//   uint32 b;
//   uint c;
// }

// // `mini`는 구조체 압축을 했기 때문에 `normal`보다 가스를 조금 사용할 것이네.
// NormalStruct normal = NormalStruct(10, 20, 30);
// MiniMe mini = MiniMe(10, 20, 30); 

// 이런 이유로, 구조체 안에서는 자네는 가능한 한 작은 크기의 정수 타입을 쓰는 것이 좋네.
// 또한 동일한 데이터 타입은 하나로 묶어놓는 것이 좋네. 
// 즉, 구조체에서 서로 옆에 있도록 선언하면 솔리디티에서 사용하는 저장 공간을 최소화한다네. 
// 예를 들면, uint c; uint32 a; uint32 b;라는 필드로 구성된 구조체가 uint32 a; uint c; uint32 b; 필드로 구성된 구조체보다 가스를 덜 소모하네. uint32 필드가 묶여있기 때문이지.