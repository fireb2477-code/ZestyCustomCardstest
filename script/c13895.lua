--Tearlaments Mirella
local s,id=GetID()

function s.initial_effect(c)

    ---------------------------------------------------
    -- 1. DISCARD:
    -- You can discard this card;
    -- add 1 "Tearlaments" card from your Deck to your hand.
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)


    ---------------------------------------------------
    -- 2. QUICK EFFECT:
    -- If your opponent Special Summons a monster:
    -- You can Special Summon this card from your hand or GY,
    -- and if you do, destroy 1 card your opponent controls.
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)


    ---------------------------------------------------
    -- 3. SENT TO GY BY CARD EFFECT:
    -- If this card is sent to the GY by card effect
    -- (except during the Damage Step):
    -- Fusion Summon 1 Fusion Monster from your Extra Deck,
    -- by placing Fusion Materials mentioned on it from
    -- your hand, field, and/or GY on the bottom of the Deck
    -- in any order, including this card from your GY.
    ---------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.fuscon)
    e3:SetTarget(s.fustg)
    e3:SetOperation(s.fusop)
    c:RegisterEffect(e3)

end


---------------------------------------------------
-- EFFECT 1
---------------------------------------------------

function s.thfilter(c)
    return c:IsSetCard(0x19a)
        and c:IsAbleToHand()
end


function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return e:GetHandler():IsDiscardable()
    end

    Duel.SendtoGrave(
        e:GetHandler(),
        REASON_COST+REASON_DISCARD
    )

end


function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,
            tp,
            LOCATION_DECK,
            0,
            1,
            nil
        )
    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_TOHAND,
        nil,
        1,
        tp,
        LOCATION_DECK
    )

end


function s.thop(e,tp,eg,ep,ev,re,r,rp)

    local g=Duel.SelectMatchingCard(
        tp,
        s.thfilter,
        tp,
        LOCATION_DECK,
        0,
        1,
        1,
        nil
    )

    if #g>0 then

        Duel.SendtoHand(
            g,
            nil,
            REASON_EFFECT
        )

        Duel.ConfirmCards(
            1-tp,
            g
        )

    end

end


---------------------------------------------------
-- EFFECT 2
-- Opponent Special Summons a monster
---------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)

    -- Only when opponent Special Summoned
    return ep~=tp
        and eg:IsExists(
            Card.IsControler,
            1,
            nil,
            1-tp
        )

end


function s.spfilter(c)
    return c:IsAbleToGrave()
end


function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then

        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(
                e,
                0,
                POS_FACEUP,
                tp,
                false,
                false
            )
            and Duel.IsExistingMatchingCard(
                s.spdestroyfilter,
                1-tp,
                LOCATION_ONFIELD,
                0,
                1,
                nil
            )

    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        e:GetHandler(),
        1,
        tp,
        LOCATION_HAND+LOCATION_GRAVE
    )

    Duel.SetOperationInfo(
        0,
        CATEGORY_DESTROY,
        nil,
        1,
        1-tp,
        LOCATION_ONFIELD
    )

end


function s.spop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    if not c:IsRelateToEffect(e) then

        if not Duel.SpecialSummon(
            c,
            0,
            tp,
            tp,
            false,
            false,
            POS_FACEUP
        ) then
            return
        end

    else

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

    end

    ---------------------------------------------------
    -- Destroy 1 card opponent controls
    ---------------------------------------------------

    local g=Duel.GetMatchingGroup(
        s.spdestroyfilter,
        1-tp,
        LOCATION_ONFIELD,
        0,
        nil
    )

    if #g>0 then

        Duel.Hint(
            HINT_SELECTMSG,
            tp,
            HINTMSG_DESTROY
        )

        local dg=g:Select(
            tp,
            1,
            1,
            nil
        )

        Duel.Destroy(
            dg,
            REASON_EFFECT
        )

    end

end


function s.spdestroyfilter(c)
    return c:IsFaceup()
        or c:IsFacedown()
end


---------------------------------------------------
-- EFFECT 3
-- Sent to GY by card effect
---------------------------------------------------

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)

    -- Must be sent to GY by card effect
    if not e:GetHandler():IsReason(REASON_EFFECT) then
        return false
    end

    -- Cannot activate during Damage Step
    if Duel.IsDamageCalculation() then
        return false
    end

    return true

end


---------------------------------------------------
-- Fusion Monster filter
---------------------------------------------------

function s.fusfilter(c)

    return c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(
            nil,
            SUMMON_TYPE_FUSION,
            0,
            false,
            false
        )

end


---------------------------------------------------
-- Fusion target
---------------------------------------------------

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then

        return Duel.IsExistingMatchingCard(
            s.fusfilter,
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


---------------------------------------------------
-- Fusion operation
---------------------------------------------------

function s.fusop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    local g=Duel.GetMatchingGroup(
        s.fusfilter,
        tp,
        LOCATION_EXTRA,
        0,
        nil
    )

    if #g==0 then
        return
    end

    ---------------------------------------------------
    -- Select Fusion Monster
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local fc=g:Select(
        tp,
        1,
        1,
        nil
    ):GetFirst()

    if not fc then
        return
    end

    ---------------------------------------------------
    -- Check Fusion Materials
    ---------------------------------------------------

    local mg=Duel.GetFusionMaterial(tp)

    ---------------------------------------------------
    -- Include Mirella itself from GY
    ---------------------------------------------------

    if c:IsLocation(LOCATION_GRAVE)
        and c:IsCanBeFusionMaterial(fc)
    then
        mg:AddCard(c)
    end

    ---------------------------------------------------
    -- Ask engine for valid Fusion Material groups
    ---------------------------------------------------

    local mat=nil

    if fc.CheckFusionMaterial then

        mat=fc:CheckFusionMaterial(
            mg,
            nil,
            tp
        )

    end

    ---------------------------------------------------
    -- If engine does not return a material group,
    -- stop safely instead of causing a script error.
    ---------------------------------------------------

    if not mat or #mat==0 then
        return
    end

    ---------------------------------------------------
    -- Select materials
    ---------------------------------------------------

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_FMATERIAL
    )

    local sg=mat:Select(
        tp,
        1,
        1,
        nil
    )

    if not sg or #sg==0 then
        return
    end

    ---------------------------------------------------
    -- Fusion Summon
    ---------------------------------------------------

    if not Duel.SpecialSummon(
        fc,
        SUMMON_TYPE_FUSION,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    ) then
        return
    end

    ---------------------------------------------------
    -- Send materials to bottom of Deck
    ---------------------------------------------------

    Duel.SendtoDeck(
        sg,
        nil,
        SEQ_BOTTOM,
        REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
    )

end