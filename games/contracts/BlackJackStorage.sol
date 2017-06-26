pragma solidity ^0.4.2;
import "./Types.sol";
import "./Deck.sol";

contract BlackJackStorage {
    using Types for *;

    /*
        CONTRACTS
    */

    Deck deck;

    /*
        CONSTANTS
    */

    uint8 BLACKJACK = 21;

    /*
        STORAGE
    */

    mapping (address => Types.Game) public games;
    mapping (address => Types.Game) public splitGames;

    /*
        CONSTRUCTOR
    */

    function BlackJackStorage(address deckAddress) {
        deck = Deck(deckAddress);
    }

    /*
        PUBLIC FUNCTIONS
    */

    function createNewGame(uint32 gameId, address _player, uint _bet)
        external
    {
        games[_player] = Types.Game({
            player: _player,
            bet: _bet,
            houseCards: new uint8[](0),
            playerCards: new uint8[](0),
            playerScore: 0,
            playerBigScore: 0,
            houseScore: 0,
            houseBigScore: 0,
            state: Types.GameState.InProgress,
            insurance: 0,
            insuranceAvailable: false,
            id: gameId
        });
    }

    function createNewSplitGame(address _player, uint _bet)
        external
    {
        splitGames[_player] = Types.Game({
            player: _player,
            bet: _bet,
            houseCards: games[_player].houseCards,
            playerCards: new uint8[](0),
            playerScore: deck.valueOf(games[_player].playerCards[1], false),
            playerBigScore: deck.valueOf(games[_player].playerCards[1], true),
            houseScore: games[_player].houseScore,
            houseBigScore: games[_player].houseBigScore,
            state: Types.GameState.InProgress,
            insurance: 0,
            insuranceAvailable: false,
            id: 0
        });

        splitGames[_player].playerCards.push(games[_player].playerCards[1]);

        games[_player].playerCards = [games[_player].playerCards[0]];
        games[_player].playerScore = deck.valueOf(games[_player].playerCards[0], false);
        games[_player].playerBigScore = deck.valueOf(games[_player].playerCards[0], true);
    }
	
    function syncSplitDealerCards(address player)
        external
    {
        splitGames[player].houseCards = games[player].houseCards;
        splitGames[player].houseScore = games[player].houseScore;
        splitGames[player].houseBigScore = games[player].houseBigScore;
    }
	
    function dealCard(Types.DealMethod typeDeal, address player, bytes32 seed)
        external
        returns (uint8)
    {
        uint8 card = uint8(deck.deal(seed));
		
		if(typeDeal == Types.DealMethod.Main){
			games[player].playerCards.push(card);
		} else if(typeDeal == Types.DealMethod.Split){
			splitGames[player].playerCards.push(card);
		} else if(typeDeal == Types.DealMethod.House){
			games[player].houseCards.push(card);
		}
		
        return card;
    }
	
    function deleteSplitGame(address player)
        external
    {
        delete splitGames[player];
    }
	
    function updatePlayerScore(bool isMain, uint8 score, uint8 bigScore, address player)
        external
    {
		if(isMain){
			games[player].playerScore = score;
			games[player].playerBigScore = bigScore;
		} else {
			splitGames[player].playerScore = score;
			splitGames[player].playerBigScore = bigScore;
		}
    }

    function updateHouseScore(bool isMain, uint8 score, uint8 bigScore, address player)
        external
    {
		if(isMain){
			games[player].houseScore = score;
			games[player].houseBigScore = bigScore;
		} else {
			splitGames[player].houseScore = score;
			splitGames[player].houseBigScore = bigScore;
		}
    }

    function updateInsurance(uint insurance, bool isMain, address player)
        external
    {
        if (isMain) {
            games[player].insurance = insurance;
        } else {
            splitGames[player].insurance = insurance;
        }
    }
	
    function updateState(Types.GameState state, bool isMain, address player)
        external
    {
        if (isMain) {
            games[player].state = state;
        } else {
            splitGames[player].state = state;
        }
    }
	
    /*
        PUBLIC GETTERS
    */

    function getSeed(uint8 id, address player)
        public
        constant
        returns(uint8)
    {
        return games[player].playerCards[id];
    }

    function getPlayerCard(uint8 id, address player)
        public
        constant
        returns(uint8)
    {
        return games[player].playerCards[id];
    }

    function getSplitCard(uint8 id, address player)
        public
        constant
        returns(uint8)
    {
        return splitGames[player].playerCards[id];
    }

    function getHouseCard(uint8 id, address player)
        public
        constant
        returns(uint8)
    {
        return games[player].houseCards[id];
    }

    function getPlayerCardsNumber(address player)
        public
        constant
        returns(uint)
    {
        return games[player].playerCards.length;
    }

    function getSplitCardsNumber(address player)
        public
        constant
        returns (uint)
    {
        return splitGames[player].playerCards.length;
    }

    function getHouseCardsNumber(address player)
        public
        constant
        returns (uint)
    {
        return games[player].houseCards.length;
    }

    function getBet(bool isMain, address player)
        public
        constant
        returns (uint)
    {
        if (isMain) {
            return games[player].bet;
        }
        return splitGames[player].bet;
    }

    function getPlayerScore(bool isMain, address player)
        public
        constant
        returns (uint8)
    {
        if (isMain) {
            return getGamePlayerScore(games[player]);
        }
        return getGamePlayerScore(splitGames[player]);
    }

    function getHouseScore(address player)
        public
        constant
        returns (uint8)
    {
        return getGameHouseScore(games[player]);
    }
	
	function getScoreGame(bool isMain, address player)
        public
        constant
        returns (uint8, uint8, uint8, uint8)
    {
		if(isMain){
			return (games[player].playerScore, 
					games[player].playerBigScore, 
					games[player].houseScore, 
					games[player].houseBigScore);
		}
				
        return (splitGames[player].playerScore, 
				splitGames[player].playerBigScore, 
				splitGames[player].houseScore, 
				splitGames[player].houseBigScore);
    }

    function getState(bool isMain, address player)
        public
        constant
        returns (Types.GameState)
    {
        if (isMain) {
            return games[player].state;
        }
        return splitGames[player].state;
    }
	
    function getId(bool isMain, address player)
        public
        constant
        returns (uint32)
    {
        if (isMain) {
            return games[player].id;
        }
        return splitGames[player].id;
    }

    function getInsurance(bool isMain, address player)
        public
        constant
        returns (uint)
    {
        if (isMain) {
            return games[player].insurance;
        }
        return splitGames[player].insurance;
    }

    function isInsuranceAvailable(address player)
        constant
        public
        returns (bool)
    {
        return getActiveGame(player).insuranceAvailable;
    }

     function isDoubleAvailable(address player)
         constant
         public
         returns (bool)
     {
         Types.Game memory game = getActiveGame(player);
         return game.state == Types.GameState.InProgress && game.playerScore > 8 && game.playerScore < 12 && game.playerCards.length == 2;
    }

    function isSplitAvailable(address player)
        constant
        public
        returns (bool)
    {
        Types.Game memory game = games[player];
        return isGameInProgress(game) && game.playerCards.length == 2 && deck.valueOf(game.playerCards[0], false) == deck.valueOf(game.playerCards[1], false);
    }

    function isMainGameInProgress(address player)
        constant
        public
        returns (bool)
    {
        return isGameInProgress(games[player]);
    }

    function isSplitGameInProgress(address player)
        constant
        public
        returns (bool)
    {
        return isGameInProgress(splitGames[player]);
    }

    function isInsurancePaymentRequired(bool isMain, address player)
        constant
        external
        returns (bool)
    {
        Types.Game memory game = games[player];
        if (!isMain) game = splitGames[player];

        return getGamePlayerScore(game) != BLACKJACK &&
               game.houseCards.length == 2 &&
               (deck.valueOf(game.houseCards[0], false) == 10 || deck.valueOf(game.houseCards[1], false) == 10) &&
               game.insurance > 0;
    }

    function isNaturalBlackJack(bool isMain, address player)
        constant
        external
        returns (bool)
    {
        Types.Game memory game = games[player];
        if (!isMain) game = splitGames[player];

        return getGamePlayerScore(game) == BLACKJACK && game.playerCards.length == 2 &&
               // (deck.isTen(game.playerCards[0]) || deck.isTen(game.playerCards[1]));
               (deck.valueOf(game.playerCards[0], false) == 10 || deck.valueOf(game.playerCards[1], false) == 10);
    }

    /*
        PRIVATE GETTERS
    */

    function getGamePlayerScore(Types.Game game)
        constant
        private
        returns (uint8)
    {
        if (game.playerBigScore > BLACKJACK) {
            return game.playerScore;
        }
        return game.playerBigScore;
    }

    function getGameHouseScore(Types.Game game)
        constant
        private
        returns (uint8)
    {
        if (game.houseBigScore > BLACKJACK) {
            return game.houseScore;
        }
        return game.houseBigScore;
    }

    function getActiveGame(address player)
        constant
        private
        returns (Types.Game)
    {
        if (isMainGameInProgress(player)) {
            return games[player];
        }
        if (isSplitGameInProgress(player)) {
            return splitGames[player];
        }
        throw;
    }

    function isGameInProgress(Types.Game game)
        constant
        private
        returns (bool)
    {
        return game.player != 0 && game.state == Types.GameState.InProgress;
    }

    /*
        PUBLIC SETTERS
    */

    function setInsuranceAvailable(bool flag, bool isMain, address player)
        external
    {
        if (isMain) {
            games[player].insuranceAvailable = flag;
        } else {
            splitGames[player].insuranceAvailable = flag;
        }
    }

    function doubleBet(bool isMain, address player)
        external
        returns (uint)
    {
        if (isMain) {
            games[player].bet *= 2;
        }
        splitGames[player].bet *= 2;
    }
}
