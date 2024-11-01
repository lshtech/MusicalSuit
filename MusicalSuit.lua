--- STEAMODDED HEADER
--- MOD_NAME: Musical Suit
--- MOD_ID: MusicalSuit
--- MOD_AUTHOR: [itayfeder, elbe]
--- MOD_DESCRIPTION: This mod add Notes suit.
--- PREFIX: musical
--- PRIORITY: 10

----------------------------------------------
------------MOD CODE -------------------------
--- Sprites
SMODS.Atlas { key = 'lc_cards', path = '8BitDeck.png', px = 71, py = 95 }
SMODS.Atlas { key = 'hc_cards', path = '8BitDeck_opt2.png', px = 71, py = 95 }
SMODS.Atlas { key = 'lc_ui', path = 'ui_assets.png', px = 18, py = 18 }
SMODS.Atlas { key = 'hc_ui', path = 'ui_assets_opt2.png', px = 18, py = 18 }
SMODS.Atlas { key = 'crystal_tuning_fork', path = 'j_crystal_tuning_fork.png', px = 71, py = 95 }
SMODS.Atlas { key = 'prideful_joker', path = 'j_prideful_joker.png', px = 71, py = 95 }
SMODS.Atlas { key = 'eclipse', path = 'c_eclipse_tarot.png', px = 71, py = 95 }
SMODS.Atlas { key = 'Blind', path = 'BlindChips.png', px = 34, py = 34, frames = 21, atlas_table = 'ANIMATION_ATLAS' }
SMODS.Atlas { key = 'modicon', path = 'ui_assets.png', px = 18, py = 18 }
SMODS.Atlas { key = 'Decks', path = 'b_musical.png', px = 71, py = 95 }

local function allow_suits(self, args)
    if args and args.initial_deck and SMODS.findModByID("SixSuits") then
        return SMODS.findModByID("SixSuits").config.allow_all_suits
    end
    return true
end

local notes_suit = SMODS.Suit {
    key = 'Notes',
    card_key = 'NOTE',
    hc_atlas = 'hc_cards',
    lc_atlas = 'lc_cards',
    hc_ui_atlas = 'hc_ui',
    lc_ui_atlas = 'lc_ui',
    pos = { y = 0 },
    ui_pos = { x = 0, y = 0 },
    hc_colour = HEX('D61BAF'),
    lc_colour = HEX('D61BAF'),
    in_pool = allow_suits,
    loc_txt = {
        singular = 'Note',
        plural = 'Notes',
    },
}

SMODS.Joker {
    key = 'prideful_joker',
    loc_txt = {
        name = "Prideful Joker",
        text = {
            "Played cards with",
            "{C:notes}Note{} suit give",
            "{C:mult}+4{} Mult when scored"
        }
    },
    config = {
        effect = "Suit Mult",
        extra = {s_mult = 4, suit = notes_suit.key}
    },
    atlas = 'prideful_joker',
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = false,
    loc_vars = function(self, info_queue, card)
        return {
            vars = { }
        }
    end
}
SMODS.Joker {
    key = 'crystal_tuning_fork',
    loc_txt = {
        name = "Crystal Tuning Fork",
        text = {
            "{C:green}#1# in #2#{} chance for",
            "played cards with",
            "{C:notes}Note{} suit to create",
            "a {C:purple}Tarot{} card when scored"
        }
    },
    config = {
        extra = {odds = 3, Xmult = 2}
    },
    atlas = 'crystal_tuning_fork',
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 7,
    unlocked = false,
    discovered = false,
    unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = notes_suit.key}},
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                G.GAME.probabilities.normal,
                card.ability.extra.odds, }
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card:is_suit(notes_suit.key) and pseudorandom('crystal_tuning_fork') < G.GAME.probabilities.normal/card.ability.extra.odds then
            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                            local new_card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, '8ba')
                            new_card:add_to_deck()
                            G.consumeables:emplace(new_card)
                            G.GAME.consumeable_buffer = 0
                        return true
                    end)}))
                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
            end
            return {
                card = self
            }
        end
    end
}
SMODS.Consumable {
    set = 'Tarot',
    loc_txt = {
        name = "The Eclipse",
        text = {
            "Converts up to",
            "{C:attention}3{} selected cards",
            "to {C:notes}Notes{}"
        }
    },
    key = 'eclipse',
    config = { suit_conv = notes_suit.key, max_highlighted = 3 },
    atlas = 'eclipse',
    pos = { x = 0, y = 0 },
    cost = 3,
    unlocked = true,
    discovered = false,
    loc_vars = function(self)
        return {
            vars = {
                self.config.max_highlighted,
                localize(self.config.suit_conv, 'suits_plural'),
                colours = { G.C.SUITS[self.config.suit_conv] },
            },
        }
    end
}
SMODS.Back {
    key = "musical_deck",
    loc_txt = {
        name = "Musical Deck",
        text = {
            "Start with a Deck",
            "containing some ",
            "{C:notes}Notes{} suit cards"
        }
    },
    atlas = 'Decks',
    pos = { x = 0, y = 0 },
    config = {musical = true, atlas = "b_musical"},
    apply = function(Self)
        G.E_MANAGER:add_event(Event({
            func = function()
                for i = #G.playing_cards, 1, -1 do
                    if i <= 26 then
                        G.playing_cards[i]:change_suit(notes_suit.key)
                    elseif i >= 27 then
                        G.playing_cards[i]:start_dissolve(nil, true)
                    end
                end
                return true
            end
        }))
    end
}
SMODS.Blind {
    key = 'void',
    loc_txt = {
        name = "The Deaf",
        text = {
            "All Note cards",
            "are debuffed"
        },
    },
    boss = { min = 1, max = 10 },
    boss_colour = notes_suit.lc_colour,
    debuff = { suit = notes_suit.key },
    atlas = 'Blind',
    pos = { x = 0, y = 1 },
    in_pool = function(self, args)
        return allow_suits
    end
}

--- Note Sounds
-- local musical_note = SMODS.Sound({
--     key = "note",
--     path = "meow1.ogg"
-- })

-- local clickref = Card.click;
-- function Card:click(change_context)
--     if self.base.suit == notes_suit.key then
--         local pitch = 0.5 + 0.1 * self.base.id
--         play_sound(musical_note.key, pitch, 0.5)
--     end
--     clickref(self, change_context)
-- end



----------------------------------------------
------------MOD CODE END---------------------