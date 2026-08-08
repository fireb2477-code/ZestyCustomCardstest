-- Priestess of White
local s,id=GetID()

local BLUE_EYES=89631139

function s.initial_effect(c)

    ---------------------------------------------------
    -- EFFECT 1
    -- If this card is added to your hand by a card effect:
    -- You can Special Summon this card.
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)


    ---------------------------------------------------
    -- EFFECT 2
    -- If this card is Normal or Special Summoned:
    -- Reveal 3 "Blue-Eyes White Dragon" from your
    -- hand, GY, and/or Deck; then reveal 1 Level 9
    -- or lower LIGHT Dragon Synchro Monster in
    -- your Extra Deck, then Special Summon it.
    -- (This is treated as a Synchro Summon.)
    ---------------------------------------------------

    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.synctg)
    e2:SetOperation(s.syncop)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)


    ---------------------------------------------------
    -- EFFECT 3
    -- If this card is in your GY:
    -- You can return 1 Synchro Monster you control
    -- to the Extra Deck; Special Summon this card,
    -- and if you do, Special Summon 1 "Blue-Eyes
    -- White Dragon" from your GY or among your
    -- banished cards.
    ---------------------------------------------------

    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,id+2)
    e4:SetTarget(s.gytg)
    e4:SetOperation(s.gyop)
    c:RegisterEffect(e4)

end


-------------------------------------------------------
-- BLUE-EYES FILTER
-------------------------------------------------------

function s.befilter(c)
    return c:IsCode(BLUE_EYES)
end


-------------------------------------------------------
-- EFFECT 1
-------------------------------------------------------

function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    return eg:IsContains(c)
        and c:IsReason(REASON_EFFECT)
end


function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(
                e,
                0,
                tp,
                false,
                false
            )
    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        e:GetHandler(),
        1,
        0,
        0
    )
end


function s.spop1(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    if not c:IsRelateToEffect(e) then
        return
    end

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.SpecialSummon(
        c,
        0,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )

end


-------------------------------------------------------
-- SYNCHRO FILTER
-------------------------------------------------------

function s.syncfilter(c)

    return c:IsType(TYPE_SYNCHRO)
        and c:IsAttribute(ATTRIBUTE_LIGHT)
        and c:IsRace(RACE_DRAGON)
        and c:GetLevel()<=9

end


-------------------------------------------------------
-- EFFECT 2 TARGET
-------------------------------------------------------

function s.synctg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then

        -- Free Monster Zone
        if Duel.GetLocationCount(
            tp,
            LOCATION_MZONE
        )<=0 then
            return false
        end

        -- At least 3 Blue-Eyes
        local bg=Duel.GetMatchingGroup(
            s.befilter,
            tp,
            LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,
            0,
            nil
        )

        if #bg<3 then
            return false
        end

        -- Valid Synchro in Extra Deck
        return Duel.IsExistingMatchingCard(
            s.syncfilter,
            tp,
            LOCATION_EXTRA,
            0,
            1,
            nil
        )

    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        nil,
        1,
        tp,
        LOCATION_EXTRA
    )

end


-------------------------------------------------------
-- EFFECT 2 OPERATION
-------------------------------------------------------

function s.syncop(e,tp,eg,ep,ev,re,r,rp)

    ---------------------------------------------------
    -- Check Monster Zone
    ---------------------------------------------------

    if Duel.GetLocationCount(
        tp,
        LOCATION_MZONE
    )<=0 then
        return
    end


    ---------------------------------------------------
    -- Get Blue-Eyes
    ---------------------------------------------------

    local bg=Duel.GetMatchingGroup(
        s.befilter,
        tp,
        LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,
        0,
        nil
    )

    if #bg<3 then
        return
    end


    ---------------------------------------------------
    -- Select 3 Blue-Eyes
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_CONFIRM
    )

    local sg=bg:Select(
        tp,
        3,
        3,
        nil
    )

    if #sg~=3 then
        return
    end


    ---------------------------------------------------
    -- Reveal Blue-Eyes
    ---------------------------------------------------

    Duel.ConfirmCards(
        1-tp,
        sg
    )


    ---------------------------------------------------
    -- Select Synchro
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local eg=Duel.SelectMatchingCard(
        tp,
        s.syncfilter,
        tp,
        LOCATION_EXTRA,
        0,
        1,
        1,
        nil
    )

    local sc=eg:GetFirst()

    if not sc then
        return
    end


    ---------------------------------------------------
    -- Reveal Synchro
    ---------------------------------------------------

    Duel.ConfirmCards(
        1-tp,
        sc
    )


    ---------------------------------------------------
    -- Special Summon as Synchro Summon
    ---------------------------------------------------

    if Duel.SpecialSummon(
        sc,
        SUMMON_TYPE_SYNCHRO,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )>0 then

        sc:CompleteProcedure()

    end

end


-------------------------------------------------------
-- EFFECT 3 FILTER
-------------------------------------------------------

function s.gyfilter(c)

    return c:IsType(TYPE_SYNCHRO)
        and c:IsAbleToExtra()

end


-------------------------------------------------------
-- EFFECT 3 TARGET
-------------------------------------------------------

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)

    local c=e:GetHandler()

    if chk==0 then

        ---------------------------------------------------
        -- Must have a Synchro Monster
        ---------------------------------------------------

        if not Duel.IsExistingMatchingCard(
            s.gyfilter,
            tp,
            LOCATION_MZONE,
            0,
            1,
            nil
        ) then
            return false
        end


        ---------------------------------------------------
        -- Must have a free Monster Zone
        ---------------------------------------------------

        if Duel.GetLocationCount(
            tp,
            LOCATION_MZONE
        )<=0 then
            return false
        end


        ---------------------------------------------------
        -- Priestess must be able to Special Summon
        ---------------------------------------------------

        if not c:IsCanBeSpecialSummoned(
            e,
            0,
            tp,
            false,
            false
        ) then
            return false
        end


        ---------------------------------------------------
        -- Must have Blue-Eyes in GY / banished
        ---------------------------------------------------

        return Duel.IsExistingMatchingCard(
            s.befilter,
            tp,
            LOCATION_GRAVE+LOCATION_REMOVED,
            0,
            1,
            nil
        )

    end


    Duel.SetOperationInfo(
        0,
        CATEGORY_TOEXTRA,
        nil,
        1,
        tp,
        LOCATION_MZONE
    )

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        c,
        1,
        tp,
        LOCATION_GRAVE
    )

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        nil,
        1,
        tp,
        LOCATION_GRAVE+LOCATION_REMOVED
    )

end


-------------------------------------------------------
-- EFFECT 3 OPERATION
-------------------------------------------------------

function s.gyop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()


    ---------------------------------------------------
    -- Make sure Priestess is still in GY
    ---------------------------------------------------

    if not c:IsLocation(LOCATION_GRAVE) then
        return
    end


    ---------------------------------------------------
    -- Select Synchro Monster
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_TODECK
    )

    local sg=Duel.SelectMatchingCard(
        tp,
        s.gyfilter,
        tp,
        LOCATION_MZONE,
        0,
        1,
        1,
        nil
    )

    local sc=sg:GetFirst()

    if not sc then
        return
    end


    ---------------------------------------------------
    -- Return Synchro to Extra Deck
    ---------------------------------------------------

    if Duel.SendtoDeck(
        sc,
        nil,
        SEQ_DECKSHUFFLE,
        REASON_EFFECT
    )==0 then
        return
    end


    ---------------------------------------------------
    -- Check Monster Zone again
    ---------------------------------------------------

    if Duel.GetLocationCount(
        tp,
        LOCATION_MZONE
    )<=0 then
        return
    end


    ---------------------------------------------------
    -- SPECIAL SUMMON PRIESTESS ITSELF
    ---------------------------------------------------

    if not c:IsCanBeSpecialSummoned(
        e,
        0,
        tp,
        false,
        false
    ) then
        return
    end


    local sum=Duel.SpecialSummon(
        c,
        0,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )

    if sum==0 then
        return
    end


    ---------------------------------------------------
    -- Priestess was successfully Special Summoned
    --
    -- Now Special Summon Blue-Eyes
    ---------------------------------------------------

    if Duel.GetLocationCount(
        tp,
        LOCATION_MZONE
    )<=0 then
        return
    end


    ---------------------------------------------------
    -- Select Blue-Eyes from GY / banished
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local bg=Duel.SelectMatchingCard(
        tp,
        s.befilter,
        tp,
        LOCATION_GRAVE+LOCATION_REMOVED,
        0,
        1,
        1,
        nil
    )

    local bc=bg:GetFirst()

    if not bc then
        return
    end


    ---------------------------------------------------
    -- Check Blue-Eyes
    ---------------------------------------------------

    if not bc:IsCanBeSpecialSummoned(
        e,
        0,
        tp,
        false,
        false
    ) then
        return
    end


    ---------------------------------------------------
    -- Special Summon Blue-Eyes
    ---------------------------------------------------

    Duel.SpecialSummon(
        bc,
        0,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )

end