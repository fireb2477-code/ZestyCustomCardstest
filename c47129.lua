-- Priestess of White
local s,id=GetID()

s.listed_names={89631139}

function s.initial_effect(c)

    ---------------------------------------------------
    -- 1. If this card is added to the hand by a card effect:
    -- Special Summon itself
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,1})
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)


    ---------------------------------------------------
    -- 2. Normal/Special Summon:
    -- Reveal 3 "Blue-Eyes White Dragon"
    -- then Special Summon a Level 9 or lower
    -- LIGHT Dragon Synchro from Extra Deck
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,2})
    e2:SetTarget(s.synctg)
    e2:SetOperation(s.syncop)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)


    ---------------------------------------------------
    -- 3. From GY:
    -- Return 1 Synchro you control to Extra Deck,
    -- Special Summon this card,
    -- then Special Summon "Blue-Eyes White Dragon"
    ---------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,3})
    e4:SetTarget(s.gytg)
    e4:SetOperation(s.gyop)
    c:RegisterEffect(e4)

end


---------------------------------------------------
-- EFFECT 1
---------------------------------------------------

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsContains(e:GetHandler())
        and e:GetHandler():IsReason(REASON_EFFECT)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
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

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    if c:IsRelateToEffect(e)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then

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
end


---------------------------------------------------
-- EFFECT 2
-- Reveal 3 Blue-Eyes White Dragon
---------------------------------------------------

function s.befilter(c)
    return c:IsCode(89631139)
end

function s.syncfilter(c,e,tp)
    return c:IsType(TYPE_SYNCHRO)
        and c:IsAttribute(ATTRIBUTE_LIGHT)
        and c:IsRace(RACE_DRAGON)
        and c:IsLevelBelow(9)
        and c:IsCanBeSpecialSummoned(
            e,
            SUMMON_TYPE_SYNCHRO,
            tp,
            false,
            false
        )
end

function s.synctg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then

        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
            return false
        end

        -- Need at least 3 Blue-Eyes
        if Duel.GetMatchingGroupCount(
            s.befilter,
            tp,
            LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,
            0,
            nil
        )<3 then
            return false
        end

        return Duel.IsExistingMatchingCard(
            s.syncfilter,
            tp,
            LOCATION_EXTRA,
            0,
            1,
            nil,
            e,
            tp
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

function s.syncop(e,tp,eg,ep,ev,re,r,rp)

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    ---------------------------------------------------
    -- Select 3 Blue-Eyes
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
    -- Reveal them
    ---------------------------------------------------

    Duel.ConfirmCards(tp,sg)

    ---------------------------------------------------
    -- Select LIGHT Dragon Synchro
    ---------------------------------------------------

    local eg=Duel.GetMatchingGroup(
        s.syncfilter,
        tp,
        LOCATION_EXTRA,
        0,
        nil,
        e,
        tp
    )

    if #eg==0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local sc=eg:Select(
        tp,
        1,
        1,
        nil
    ):GetFirst()

    if not sc then
        return
    end

    ---------------------------------------------------
    -- Reveal selected Synchro
    ---------------------------------------------------

    Duel.ConfirmCards(tp,sc)

    ---------------------------------------------------
    -- Special Summon as Synchro
    ---------------------------------------------------

    if sc:IsRelateToEffect(e)
        or sc:IsLocation(LOCATION_EXTRA) then

        Duel.SpecialSummon(
            sc,
            SUMMON_TYPE_SYNCHRO,
            tp,
            tp,
            false,
            false,
            POS_FACEUP
        )
    end
end


---------------------------------------------------
-- EFFECT 3
-- GY effect
---------------------------------------------------

function s.gysynfilter(c)
    return c:IsFaceup()
        and c:IsType(TYPE_SYNCHRO)
        and c:IsAbleToExtra()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then

        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
            return false
        end

        if not e:GetHandler():IsCanBeSpecialSummoned(
            e,
            0,
            tp,
            false,
            false
        ) then
            return false
        end

        return Duel.IsExistingMatchingCard(
            s.gysynfilter,
            tp,
            LOCATION_MZONE,
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
        e:GetHandler(),
        1,
        tp,
        LOCATION_GRAVE
    )
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    ---------------------------------------------------
    -- Return 1 Synchro to Extra Deck
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_TODECK
    )

    local g=Duel.SelectMatchingCard(
        tp,
        s.gysynfilter,
        tp,
        LOCATION_MZONE,
        0,
        1,
        1,
        nil
    )

    local tc=g:GetFirst()

    if not tc then
        return
    end

    if Duel.SendtoDeck(
        tc,
        nil,
        SEQ_DECKSHUFFLE,
        REASON_EFFECT
    )==0 then
        return
    end

    ---------------------------------------------------
    -- Special Summon Priestess
    ---------------------------------------------------

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    if not c:IsRelateToEffect(e)
        or not c:IsCanBeSpecialSummoned(
            e,
            0,
            tp,
            false,
            false
        ) then
        return
    end

    if Duel.SpecialSummon(
        c,
        0,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )==0 then
        return
    end

    ---------------------------------------------------
    -- Special Summon Blue-Eyes
    -- from GY or banished
    ---------------------------------------------------

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    local bg=Duel.GetMatchingGroup(
        s.befilter,
        tp,
        LOCATION_GRAVE+LOCATION_REMOVED,
        0,
        nil
    )

    if #bg==0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local bc=bg:Select(
        tp,
        1,
        1,
        nil
    ):GetFirst()

    if bc and bc:IsCanBeSpecialSummoned(
        e,
        0,
        tp,
        false,
        false
    ) then

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
end