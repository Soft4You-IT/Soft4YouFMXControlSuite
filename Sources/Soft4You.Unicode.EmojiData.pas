unit Soft4You.Unicode.EmojiData;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ *******************************************************************************
  Soft4You.Unicode.EmojiData  -  Common emoji catalogue for the HTML editor emoji picker.
  No FMX dependency; usable from any form or component.
  Source file MUST be saved as UTF-8 (emoji glyphs are stored as literals).
  ******************************************************************************* }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

// -- Public types --------------------------------------------------------------

type
  TEmoji = record
    Glyph: string; // UTF-16 string (SMP emoji = 2 WideChar surrogate pair)
    Name:  string; // Human-readable name, populated from resourcestring
  end;

  TEmojiCategoryKind = (
    eckAll,
    eckActivities,
    eckAnimals,
    eckFood,
    eckObjects,
    eckPeople,
    eckSmileys,
    eckSymbols,
    eckTravel
  );

  TEmojiCategory = record
    Kind:  TEmojiCategoryKind;
    Items: TArray<TEmoji>;
    Name:  string;
  end;

  TEmojiData = class
  private
    class var FCategories: TArray<TEmojiCategory>;
    class function Build: TArray<TEmojiCategory>;
  public
    class function Categories: TArray<TEmojiCategory>;
    class function Emojis(ACategory: TEmojiCategoryKind = eckAll): TArray<TEmoji>;
  end;

// -- Localizable strings -------------------------------------------------------

resourcestring
  // Category names
  S_EMOJI_CAT_ACTIVITIES    = 'Activities';
  S_EMOJI_CAT_ANIMALS       = 'Animals & Nature';
  S_EMOJI_CAT_FOOD          = 'Food & Drink';
  S_EMOJI_CAT_OBJECTS       = 'Objects & Tech';
  S_EMOJI_CAT_PEOPLE        = 'People & Gestures';
  S_EMOJI_CAT_SMILEYS       = 'Smileys & Emotion';
  S_EMOJI_CAT_SYMBOLS       = 'Signs & Symbols';
  S_EMOJI_CAT_TRAVEL        = 'Travel & Places';

  // Smileys & Emotion
  S_EMOJI_BEAMING           = 'Beaming Face with Smiling Eyes';
  S_EMOJI_CRYING            = 'Loudly Crying Face';
  S_EMOJI_GRINNING_BIG_EYES = 'Grinning Face with Big Eyes';
  S_EMOJI_GRINNING_FACE     = 'Grinning Face';
  S_EMOJI_GRINNING_SWEAT    = 'Grinning Face with Sweat';
  S_EMOJI_HALO              = 'Smiling Face with Halo';
  S_EMOJI_HEART_EYES        = 'Smiling Face with Heart-Eyes';
  S_EMOJI_HEARTS            = 'Smiling Face with Hearts';
  S_EMOJI_KISS              = 'Face Blowing a Kiss';
  S_EMOJI_NEUTRAL           = 'Neutral Face';
  S_EMOJI_PENSIVE           = 'Pensive Face';
  S_EMOJI_POUTING           = 'Pouting Face';
  S_EMOJI_ROFL              = 'Rolling on the Floor Laughing';
  S_EMOJI_SAVORING          = 'Face Savoring Food';
  S_EMOJI_SCREAMING         = 'Face Screaming in Fear';
  S_EMOJI_SMILING_EYES      = 'Smiling Face with Smiling Eyes';
  S_EMOJI_SMIRKING          = 'Smirking Face';
  S_EMOJI_SQUINTING         = 'Grinning Squinting Face';
  S_EMOJI_SUNGLASSES        = 'Smiling Face with Sunglasses';
  S_EMOJI_TEARS_JOY         = 'Face with Tears of Joy';
  S_EMOJI_THINKING          = 'Thinking Face';
  S_EMOJI_WINKING           = 'Winking Face';

  // People & Gestures
  S_EMOJI_CARTWHEEL         = 'Person Cartwheeling';
  S_EMOJI_CLAPPING          = 'Clapping Hands';
  S_EMOJI_CROSSED_FINGERS   = 'Crossed Fingers';
  S_EMOJI_FACEPALM          = 'Person Facepalming';
  S_EMOJI_FLEXED_BICEPS     = 'Flexed Biceps';
  S_EMOJI_FOLDED_HANDS      = 'Folded Hands';
  S_EMOJI_HANDSHAKE         = 'Handshake';
  S_EMOJI_INDEX_DOWN        = 'Backhand Index Pointing Down';
  S_EMOJI_INDEX_LEFT        = 'Backhand Index Pointing Left';
  S_EMOJI_INDEX_RIGHT       = 'Backhand Index Pointing Right';
  S_EMOJI_INDEX_UP          = 'Index Pointing Up';
  S_EMOJI_INDEX_UP_BACK     = 'Backhand Index Pointing Up';
  S_EMOJI_OK_HAND           = 'OK Hand';
  S_EMOJI_RAISED_FIST       = 'Raised Fist';
  S_EMOJI_RAISED_HAND       = 'Raised Hand';
  S_EMOJI_RAISING_HANDS     = 'Raising Hands';
  S_EMOJI_SHRUG             = 'Person Shrugging';
  S_EMOJI_THUMBS_DOWN       = 'Thumbs Down';
  S_EMOJI_THUMBS_UP         = 'Thumbs Up';
  S_EMOJI_VICTORY           = 'Victory Hand';
  S_EMOJI_WAVING            = 'Waving Hand';

  // Animals & Nature
  S_EMOJI_BEAR              = 'Bear Face';
  S_EMOJI_BEE               = 'Honeybee';
  S_EMOJI_BUTTERFLY         = 'Butterfly';
  S_EMOJI_CAT_FACE          = 'Cat Face';
  S_EMOJI_CHERRY_BLOSSOM    = 'Cherry Blossom';
  S_EMOJI_COW               = 'Cow Face';
  S_EMOJI_DOG_FACE          = 'Dog Face';
  S_EMOJI_FOX               = 'Fox Face';
  S_EMOJI_FROG              = 'Frog Face';
  S_EMOJI_KOALA             = 'Koala Face';
  S_EMOJI_LION              = 'Lion Face';
  S_EMOJI_MOON              = 'Crescent Moon';
  S_EMOJI_PANDA             = 'Panda Face';
  S_EMOJI_PIG               = 'Pig Face';
  S_EMOJI_RAINBOW           = 'Rainbow';
  S_EMOJI_ROSE              = 'Rose';
  S_EMOJI_SUN               = 'Sun';
  S_EMOJI_SUNFLOWER         = 'Sunflower';
  S_EMOJI_TIGER             = 'Tiger Face';
  S_EMOJI_TREE              = 'Deciduous Tree';

  // Food & Drink
  S_EMOJI_BASEBALL          = 'Baseball'; // NOTE: in Activities section
  S_EMOJI_BEER              = 'Beer Mug';
  S_EMOJI_BENTO             = 'Bento Box';
  S_EMOJI_BIRTHDAY_CAKE     = 'Birthday Cake';
  S_EMOJI_BOWL              = 'Steaming Bowl';
  S_EMOJI_CANDY             = 'Candy';
  S_EMOJI_CHOCOLATE         = 'Chocolate Bar';
  S_EMOJI_CLINKING_GLASSES  = 'Clinking Glasses';
  S_EMOJI_CUP_STRAW         = 'Cup with Straw';
  S_EMOJI_HAMBURGER         = 'Hamburger';
  S_EMOJI_HOT_BEVERAGE      = 'Hot Beverage';
  S_EMOJI_ICE_CREAM         = 'Soft Ice Cream';
  S_EMOJI_JUICE_BOX         = 'Beverage Box';
  S_EMOJI_LOLLIPOP          = 'Lollipop';
  S_EMOJI_PIZZA             = 'Pizza';
  S_EMOJI_SHORTCAKE         = 'Shortcake';
  S_EMOJI_SUSHI             = 'Sushi';
  S_EMOJI_TACO              = 'Taco';
  S_EMOJI_TEACUP            = 'Teacup Without Handle';
  S_EMOJI_TROPICAL_DRINK    = 'Tropical Drink';
  S_EMOJI_WINE              = 'Wine Glass';

  // Travel & Places
  S_EMOJI_AIRPLANE          = 'Airplane';
  S_EMOJI_BEACH             = 'Beach with Umbrella';
  S_EMOJI_BUS               = 'Bus';
  S_EMOJI_CAMPING           = 'Camping';
  S_EMOJI_CAR               = 'Automobile';
  S_EMOJI_CASTLE            = 'European Castle';
  S_EMOJI_CITYSCAPE         = 'Cityscape at Dusk';
  S_EMOJI_FERRIS_WHEEL      = 'Ferris Wheel';
  S_EMOJI_GLOBE_AMERICAS    = 'Globe Showing Americas';
  S_EMOJI_GLOBE_ASIA        = 'Globe Showing Asia-Australia';
  S_EMOJI_GLOBE_EUROPE      = 'Globe Showing Europe-Africa';
  S_EMOJI_HOUSE             = 'House';
  S_EMOJI_MOUNTAIN          = 'Snow-Capped Mountain';
  S_EMOJI_ROCKET            = 'Rocket';
  S_EMOJI_SHIP              = 'Ship';
  S_EMOJI_STATUE_LIBERTY    = 'Statue of Liberty';
  S_EMOJI_TENT              = 'Tent';
  S_EMOJI_TOKYO_TOWER       = 'Tokyo Tower';
  S_EMOJI_TRAIN             = 'Locomotive';
  S_EMOJI_WORLD_MAP         = 'World Map';

  // Activities
  S_EMOJI_BASKETBALL        = 'Basketball';
  S_EMOJI_BOOKS             = 'Books';
  S_EMOJI_BULLSEYE          = 'Bullseye';
  S_EMOJI_CLAPPER           = 'Clapper Board';
  S_EMOJI_FOOTBALL          = 'American Football';
  S_EMOJI_GAME_DIE          = 'Game Die';
  S_EMOJI_GUITAR            = 'Guitar';
  S_EMOJI_HEADPHONE         = 'Headphone';
  S_EMOJI_KEYBOARD_MUSIC    = 'Musical Keyboard';
  S_EMOJI_MICROPHONE        = 'Microphone';
  S_EMOJI_PALETTE           = 'Artist Palette';
  S_EMOJI_POOL              = 'Pool 8 Ball';
  S_EMOJI_SOCCER            = 'Soccer Ball';
  S_EMOJI_TENNIS            = 'Tennis';
  S_EMOJI_THEATER           = 'Performing Arts';
  S_EMOJI_VIDEO_GAME        = 'Video Game';
  S_EMOJI_VOLLEYBALL        = 'Volleyball';
  S_EMOJI_WEIGHTS           = 'Person Lifting Weights';

  // Objects & Tech
  S_EMOJI_BELL              = 'Bell';
  S_EMOJI_BRIEFCASE         = 'Briefcase';
  S_EMOJI_BULB              = 'Light Bulb';
  S_EMOJI_CAMERA            = 'Camera';
  S_EMOJI_DESKTOP           = 'Desktop Computer';
  S_EMOJI_EMAIL             = 'E-Mail';
  S_EMOJI_FLASHLIGHT        = 'Flashlight';
  S_EMOJI_FLOPPY            = 'Floppy Disk';
  S_EMOJI_GEAR              = 'Gear';
  S_EMOJI_GIFT              = 'Wrapped Gift';
  S_EMOJI_HAMMER            = 'Hammer';
  S_EMOJI_KEY               = 'Key';
  S_EMOJI_LAPTOP            = 'Laptop';
  S_EMOJI_LOCKED            = 'Locked';
  S_EMOJI_MAGNET            = 'Magnet';
  S_EMOJI_MEMO              = 'Memo';
  S_EMOJI_PAPERCLIP         = 'Paperclip';
  S_EMOJI_PHONE             = 'Mobile Phone';
  S_EMOJI_PUSHPIN           = 'Pushpin';
  S_EMOJI_WRENCH            = 'Wrench';

  // Signs & Symbols
  S_EMOJI_BLACK_HEART       = 'Black Heart';
  S_EMOJI_BLUE_CIRCLE       = 'Blue Circle';
  S_EMOJI_BLUE_HEART        = 'Blue Heart';
  S_EMOJI_CHECK             = 'Check Mark Button';
  S_EMOJI_CONFETTI          = 'Confetti Ball';
  S_EMOJI_CROSS             = 'Cross Mark';
  S_EMOJI_DIZZY             = 'Dizzy';
  S_EMOJI_FIRE              = 'Fire';
  S_EMOJI_GLOWING_STAR      = 'Glowing Star';
  S_EMOJI_GREEN_CIRCLE      = 'Green Circle';
  S_EMOJI_GREEN_HEART       = 'Green Heart';
  S_EMOJI_HUNDRED           = 'Hundred Points';
  S_EMOJI_ORANGE_HEART      = 'Orange Heart';
  S_EMOJI_PARTY_POPPER      = 'Party Popper';
  S_EMOJI_PURPLE_HEART      = 'Purple Heart';
  S_EMOJI_RED_CIRCLE        = 'Red Circle';
  S_EMOJI_RED_HEART         = 'Red Heart';
  S_EMOJI_STAR              = 'Star';
  S_EMOJI_WARNING           = 'Warning';
  S_EMOJI_YELLOW_HEART      = 'Yellow Heart';

implementation

// -- Private helper ------------------------------------------------------------

function E(const AGlyph, AName: string): TEmoji; inline;
begin
  Result.Glyph := AGlyph;
  Result.Name  := AName;
end;

// -- TEmojiData ----------------------------------------------------------------

class function TEmojiData.Build: TArray<TEmojiCategory>;
var
  LCats: TArray<TEmojiCategory>;
begin
  SetLength(LCats, 8);

  // -- 0: Smileys & Emotion ---------------------------------------------------
  LCats[0].Kind  := eckSmileys;
  LCats[0].Name  := S_EMOJI_CAT_SMILEYS;
  LCats[0].Items := TArray<TEmoji>.Create(
    E('😀', S_EMOJI_GRINNING_FACE),
    E('😃', S_EMOJI_GRINNING_BIG_EYES),
    E('😄', S_EMOJI_SMILING_EYES),
    E('😁', S_EMOJI_BEAMING),
    E('😆', S_EMOJI_SQUINTING),
    E('😅', S_EMOJI_GRINNING_SWEAT),
    E('🤣', S_EMOJI_ROFL),
    E('😂', S_EMOJI_TEARS_JOY),
    E('😊', S_EMOJI_SMILING_EYES),
    E('😇', S_EMOJI_HALO),
    E('🥰', S_EMOJI_HEARTS),
    E('😍', S_EMOJI_HEART_EYES),
    E('😘', S_EMOJI_KISS),
    E('😋', S_EMOJI_SAVORING),
    E('😉', S_EMOJI_WINKING),
    E('🤔', S_EMOJI_THINKING),
    E('😐', S_EMOJI_NEUTRAL),
    E('😏', S_EMOJI_SMIRKING),
    E('😔', S_EMOJI_PENSIVE),
    E('😭', S_EMOJI_CRYING),
    E('😱', S_EMOJI_SCREAMING),
    E('😎', S_EMOJI_SUNGLASSES),
    E('😡', S_EMOJI_POUTING)
  );

  // -- 1: People & Gestures --------------------------------------------------
  LCats[1].Kind  := eckPeople;
  LCats[1].Name  := S_EMOJI_CAT_PEOPLE;
  LCats[1].Items := TArray<TEmoji>.Create(
    E('👍', S_EMOJI_THUMBS_UP),
    E('👎', S_EMOJI_THUMBS_DOWN),
    E('👋', S_EMOJI_WAVING),
    E('🤝', S_EMOJI_HANDSHAKE),
    E('🙏', S_EMOJI_FOLDED_HANDS),
    E('💪', S_EMOJI_FLEXED_BICEPS),
    E('🤦', S_EMOJI_FACEPALM),
    E('🤷', S_EMOJI_SHRUG),
    E('👏', S_EMOJI_CLAPPING),
    E('🙌', S_EMOJI_RAISING_HANDS),
    E('✊', S_EMOJI_RAISED_FIST),
    E('🤞', S_EMOJI_CROSSED_FINGERS),
    E('✌️', S_EMOJI_VICTORY),
    E('✋', S_EMOJI_RAISED_HAND),
    E('👌', S_EMOJI_OK_HAND),
    E('☝️', S_EMOJI_INDEX_UP),
    E('👈', S_EMOJI_INDEX_LEFT),
    E('👉', S_EMOJI_INDEX_RIGHT),
    E('👆', S_EMOJI_INDEX_UP_BACK),
    E('👇', S_EMOJI_INDEX_DOWN)
  );

  // -- 2: Animals & Nature ---------------------------------------------------
  LCats[2].Kind  := eckAnimals;
  LCats[2].Name  := S_EMOJI_CAT_ANIMALS;
  LCats[2].Items := TArray<TEmoji>.Create(
    E('🐶', S_EMOJI_DOG_FACE),
    E('🐱', S_EMOJI_CAT_FACE),
    E('🐻', S_EMOJI_BEAR),
    E('🦊', S_EMOJI_FOX),
    E('🐼', S_EMOJI_PANDA),
    E('🐨', S_EMOJI_KOALA),
    E('🐯', S_EMOJI_TIGER),
    E('🦁', S_EMOJI_LION),
    E('🐮', S_EMOJI_COW),
    E('🐷', S_EMOJI_PIG),
    E('🐸', S_EMOJI_FROG),
    E('🦋', S_EMOJI_BUTTERFLY),
    E('🐝', S_EMOJI_BEE),
    E('🌸', S_EMOJI_CHERRY_BLOSSOM),
    E('🌹', S_EMOJI_ROSE),
    E('🌻', S_EMOJI_SUNFLOWER),
    E('🌳', S_EMOJI_TREE),
    E('🌈', S_EMOJI_RAINBOW),
    E('🌙', S_EMOJI_MOON),
    E('☀️', S_EMOJI_SUN)
  );

  // -- 3: Food & Drink -------------------------------------------------------
  LCats[3].Kind  := eckFood;
  LCats[3].Name  := S_EMOJI_CAT_FOOD;
  LCats[3].Items := TArray<TEmoji>.Create(
    E('🍕', S_EMOJI_PIZZA),
    E('🍔', S_EMOJI_HAMBURGER),
    E('🌮', S_EMOJI_TACO),
    E('🍜', S_EMOJI_BOWL),
    E('🍣', S_EMOJI_SUSHI),
    E('🍱', S_EMOJI_BENTO),
    E('🍦', S_EMOJI_ICE_CREAM),
    E('🍰', S_EMOJI_SHORTCAKE),
    E('🎂', S_EMOJI_BIRTHDAY_CAKE),
    E('🍫', S_EMOJI_CHOCOLATE),
    E('🍭', S_EMOJI_LOLLIPOP),
    E('🍬', S_EMOJI_CANDY),
    E('☕', S_EMOJI_HOT_BEVERAGE),
    E('🍵', S_EMOJI_TEACUP),
    E('🧃', S_EMOJI_JUICE_BOX),
    E('🥤', S_EMOJI_CUP_STRAW),
    E('🍺', S_EMOJI_BEER),
    E('🥂', S_EMOJI_CLINKING_GLASSES),
    E('🍷', S_EMOJI_WINE),
    E('🍹', S_EMOJI_TROPICAL_DRINK)
  );

  // -- 4: Travel & Places ---------------------------------------------------
  LCats[4].Kind  := eckTravel;
  LCats[4].Name  := S_EMOJI_CAT_TRAVEL;
  LCats[4].Items := TArray<TEmoji>.Create(
    E('✈️', S_EMOJI_AIRPLANE),
    E('🚗', S_EMOJI_CAR),
    E('🚌', S_EMOJI_BUS),
    E('🚂', S_EMOJI_TRAIN),
    E('🚢', S_EMOJI_SHIP),
    E('🏠', S_EMOJI_HOUSE),
    E('🏖️', S_EMOJI_BEACH),
    E('🏔️', S_EMOJI_MOUNTAIN),
    E('🗺️', S_EMOJI_WORLD_MAP),
    E('🌍', S_EMOJI_GLOBE_EUROPE),
    E('🌏', S_EMOJI_GLOBE_ASIA),
    E('🌎', S_EMOJI_GLOBE_AMERICAS),
    E('🗽', S_EMOJI_STATUE_LIBERTY),
    E('🏰', S_EMOJI_CASTLE),
    E('🚀', S_EMOJI_ROCKET),
    E('🎡', S_EMOJI_FERRIS_WHEEL),
    E('🗼', S_EMOJI_TOKYO_TOWER),
    E('🌆', S_EMOJI_CITYSCAPE),
    E('🏕️', S_EMOJI_CAMPING),
    E('⛺', S_EMOJI_TENT)
  );

  // -- 5: Activities ---------------------------------------------------------
  LCats[5].Kind  := eckActivities;
  LCats[5].Name  := S_EMOJI_CAT_ACTIVITIES;
  LCats[5].Items := TArray<TEmoji>.Create(
    E('⚽', S_EMOJI_SOCCER),
    E('🏀', S_EMOJI_BASKETBALL),
    E('🏈', S_EMOJI_FOOTBALL),
    E('⚾', S_EMOJI_BASEBALL),
    E('🎾', S_EMOJI_TENNIS),
    E('🏐', S_EMOJI_VOLLEYBALL),
    E('🎱', S_EMOJI_POOL),
    E('🎮', S_EMOJI_VIDEO_GAME),
    E('🎸', S_EMOJI_GUITAR),
    E('🎹', S_EMOJI_KEYBOARD_MUSIC),
    E('🎨', S_EMOJI_PALETTE),
    E('📚', S_EMOJI_BOOKS),
    E('🎯', S_EMOJI_BULLSEYE),
    E('🎲', S_EMOJI_GAME_DIE),
    E('🏋️', S_EMOJI_WEIGHTS),
    E('🤸', S_EMOJI_CARTWHEEL),
    E('🎭', S_EMOJI_THEATER),
    E('🎬', S_EMOJI_CLAPPER),
    E('🎤', S_EMOJI_MICROPHONE),
    E('🎧', S_EMOJI_HEADPHONE)
  );

  // -- 6: Objects & Tech -----------------------------------------------------
  LCats[6].Kind  := eckObjects;
  LCats[6].Name  := S_EMOJI_CAT_OBJECTS;
  LCats[6].Items := TArray<TEmoji>.Create(
    E('📱', S_EMOJI_PHONE),
    E('💻', S_EMOJI_LAPTOP),
    E('🖥️', S_EMOJI_DESKTOP),
    E('💡', S_EMOJI_BULB),
    E('🔦', S_EMOJI_FLASHLIGHT),
    E('📷', S_EMOJI_CAMERA),
    E('🎁', S_EMOJI_GIFT),
    E('💼', S_EMOJI_BRIEFCASE),
    E('🔑', S_EMOJI_KEY),
    E('🔒', S_EMOJI_LOCKED),
    E('🔔', S_EMOJI_BELL),
    E('📧', S_EMOJI_EMAIL),
    E('📝', S_EMOJI_MEMO),
    E('📌', S_EMOJI_PUSHPIN),
    E('📎', S_EMOJI_PAPERCLIP),
    E('🔧', S_EMOJI_WRENCH),
    E('🔨', S_EMOJI_HAMMER),
    E('⚙️', S_EMOJI_GEAR),
    E('🧲', S_EMOJI_MAGNET),
    E('💾', S_EMOJI_FLOPPY)
  );

  // -- 7: Signs & Symbols ---------------------------------------------------
  LCats[7].Kind  := eckSymbols;
  LCats[7].Name  := S_EMOJI_CAT_SYMBOLS;
  LCats[7].Items := TArray<TEmoji>.Create(
    E('❤️', S_EMOJI_RED_HEART),
    E('🧡', S_EMOJI_ORANGE_HEART),
    E('💛', S_EMOJI_YELLOW_HEART),
    E('💚', S_EMOJI_GREEN_HEART),
    E('💙', S_EMOJI_BLUE_HEART),
    E('💜', S_EMOJI_PURPLE_HEART),
    E('🖤', S_EMOJI_BLACK_HEART),
    E('💯', S_EMOJI_HUNDRED),
    E('✅', S_EMOJI_CHECK),
    E('❌', S_EMOJI_CROSS),
    E('⚠️', S_EMOJI_WARNING),
    E('🔴', S_EMOJI_RED_CIRCLE),
    E('🟢', S_EMOJI_GREEN_CIRCLE),
    E('🔵', S_EMOJI_BLUE_CIRCLE),
    E('⭐', S_EMOJI_STAR),
    E('💫', S_EMOJI_DIZZY),
    E('🌟', S_EMOJI_GLOWING_STAR),
    E('🎉', S_EMOJI_PARTY_POPPER),
    E('🎊', S_EMOJI_CONFETTI),
    E('🔥', S_EMOJI_FIRE)
  );

  Result := LCats;
end;

class function TEmojiData.Categories: TArray<TEmojiCategory>;
begin
  if Length(FCategories) = 0 then
    FCategories := Build;
  Result := FCategories;
end;

class function TEmojiData.Emojis(ACategory: TEmojiCategoryKind): TArray<TEmoji>;
var
  LCategories: TArray<TEmojiCategory>;
  LCategory: TEmojiCategory;
  LTotalCount: Integer;
  LOffset: Integer;
begin
  LCategories := Categories;
  if ACategory <> eckAll then
  begin
    for LCategory in LCategories do
      if LCategory.Kind = ACategory then
        Exit(LCategory.Items);
    Result := [];
    Exit;
  end;
  LTotalCount := 0;
  for LCategory in LCategories do
    Inc(LTotalCount, Length(LCategory.Items));
  SetLength(Result, LTotalCount);
  LOffset := 0;
  for LCategory in LCategories do
    for var LItem in LCategory.Items do
    begin
      Result[LOffset] := LItem;
      Inc(LOffset);
    end;
end;

end.
