# Tasks

## Milestone 1
- Load matches from file
- Show matches
- Show standings
- Sidekick job to update matches

# Extra

## Thoughts
- Minitest
- Create a client at lib/clients
- Rake task to fetch all matches as a one off
- Create a Sidekick job to run it once a day to update matches
- Sidekick cron gem

https://api.soccerdataapi.com/league/?auth_token=3486903b2644221b1cae0010139790fbc5a55b8b
{"id":216,"name":"Serie B","is_cup":false,"country":{"id":67,"name":"brazil"}}
{"id":3969,"name":"Vitoria","country":{"id":67,"name":"brazil"},"stadium":{"id":1974,"name":"Estadio Manoel Barradas","city":"Salvador, Bahia"},"is_nation":false}


                    {
                        "id": 741485,
                        "date": "16/04/2023",
                        "time": "21:00",
                        "teams": {
                            "home": {
                                "id": 3969,
                                "name": "Vitoria"
                            },
                            "away": {
                                "id": 3968,
                                "name": "Ponte Preta"
                            }
                        },
                        "status": "finished",
                        "minute": -1,
                        "winner": "home",
                        "has_extra_time": false,
                        "has_penalties": false,
                        "goals": {
                            "home_ht_goals": 2,
                            "away_ht_goals": 0,
                            "home_ft_goals": 3,
                            "away_ft_goals": 0,
                            "home_et_goals": -1,
                            "away_et_goals": -1,
                            "home_pen_goals": -1,
                            "away_pen_goals": -1
                        },
                        "events": [
                            {
                                "event_type": "goal",
                                "event_minute": "20",
                                "team": "home",
                                "player": {
                                    "id": 57006,
                                    "name": "Zeca"
                                },
                                "assist_player": null
                            },
                            {
                                "event_type": "goal",
                                "event_minute": "45",
                                "team": "home",
                                "player": {
                                    "id": 57146,
                                    "name": "Osvaldo"
                                },
                                "assist_player": {
                                    "id": 57006,
                                    "name": "Zeca"
                                }
                            },
                            {
                                "event_type": "goal",
                                "event_minute": "86",
                                "team": "home",
                                "player": {
                                    "id": 57020,
                                    "name": "Rodrigo Andrade"
                                },
                                "assist_player": {
                                    "id": 57048,
                                    "name": "Railan"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "41",
                                "team": "home",
                                "player": {
                                    "id": 57006,
                                    "name": "Zeca"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "74",
                                "team": "home",
                                "player": {
                                    "id": 57010,
                                    "name": "Marco Antônio"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "57",
                                "team": "home",
                                "player": {
                                    "id": 57020,
                                    "name": "Rodrigo Andrade"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "63",
                                "team": "home",
                                "player": {
                                    "id": 57119,
                                    "name": "Léo Gamalho"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "18",
                                "team": "away",
                                "player": {
                                    "id": 57198,
                                    "name": "Felipe Amaral"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "66",
                                "team": "home",
                                "player_in": {
                                    "id": 57026,
                                    "name": "Thiago Lopes"
                                },
                                "player_out": {
                                    "id": 57044,
                                    "name": "Giovanni Augusto"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "67",
                                "team": "home",
                                "player_in": {
                                    "id": 57101,
                                    "name": "Welder"
                                },
                                "player_out": {
                                    "id": 57119,
                                    "name": "Léo Gamalho"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "85",
                                "team": "home",
                                "player": {
                                    "id": 57004,
                                    "name": "João Victor"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "71",
                                "team": "home",
                                "player_in": {
                                    "id": 57004,
                                    "name": "João Victor"
                                },
                                "player_out": {
                                    "id": 57000,
                                    "name": "Camutanga"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "79",
                                "team": "home",
                                "player_in": {
                                    "id": 57048,
                                    "name": "Railan"
                                },
                                "player_out": {
                                    "id": 57146,
                                    "name": "Osvaldo"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "79",
                                "team": "home",
                                "player_in": {
                                    "id": 57023,
                                    "name": "Léo Gomes"
                                },
                                "player_out": {
                                    "id": 57010,
                                    "name": "Marco Antônio"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "46",
                                "team": "away",
                                "player_in": {
                                    "id": 57221,
                                    "name": "Jean Carlos"
                                },
                                "player_out": {
                                    "id": 57191,
                                    "name": "Júnior Tavares"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "65",
                                "team": "away",
                                "player": {
                                    "id": 57041,
                                    "name": "Cássio Gabriel"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "46",
                                "team": "away",
                                "player_in": {
                                    "id": 57041,
                                    "name": "Cássio Gabriel"
                                },
                                "player_out": {
                                    "id": 57198,
                                    "name": "Felipe Amaral"
                                }
                            },
                            {
                                "event_type": "yellow_card",
                                "event_minute": "66",
                                "team": "away",
                                "player": {
                                    "id": 57103,
                                    "name": "Gui Pira"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "61",
                                "team": "away",
                                "player_in": {
                                    "id": 57103,
                                    "name": "Gui Pira"
                                },
                                "player_out": {
                                    "id": 57323,
                                    "name": "Pablo Dyego"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "70",
                                "team": "away",
                                "player_in": {
                                    "id": 57125,
                                    "name": "Maílton"
                                },
                                "player_out": {
                                    "id": 57120,
                                    "name": "Weverton"
                                }
                            },
                            {
                                "event_type": "substitution",
                                "event_minute": "71",
                                "team": "away",
                                "player_in": {
                                    "id": 57253,
                                    "name": "Samuel Andrade"
                                },
                                "player_out": {
                                    "id": 57261,
                                    "name": "Luiz Felipe"
                                }
                            }
                        ],
                        "odds": {
                            "match_winner": {},
                            "over_under": {},
                            "handicap": {}
                        },
                        "match_preview": {
                            "has_preview": false,
                            "word_count": -1
                        }
