--Tearlaments Mirella
local s,id=GetID()

function s.initial_effect(c)

    --------------------------------------------------
    -- 1. You can discard this card;
    -- add 1 "Tearlaments" card from your Deck to your hand.
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --------------------------------------------------
    -- 2. If your opponent Special Summons a monster:
    -- You can Special Summon this card from your hand or GY,
    -- and if you do, destroy 1 card your opponent controls.
    --------------------------------------------------
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

    --------------------------------------------------
    -- 3. If this card is sent to the GY by card effect
    -- (except during the Damage Step):
    -- Fusion Summon 1 Fusion Monster from your Extra Deck
    -- by placing the Fusion Materials mentioned on it
    -- from your hand, field, and/or GY on the bottom
    -- of the Deck in any order, including this card
    -- from your GY.
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.fuscon)
    e3:SetTarget(s.fustg)
    e3:SetOperation(s.fusop)
    c:RegisterEffect(e3)

end


--------------------------------------------------
-- EFFECT 1
--------------------------------------------------

function s.thfilter(c)
    return c:IsSetCard(0x182)
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


--------------------------------------------------
-- EFFECT 2
--------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)

    -- Opponent must be the one who Special Summoned
    return eg:IsExists(
        Card.IsControler,
        1,
        nil,
        1-tp
    )

end

function s.spfilter(c)
    return c:IsAbleToDestroy()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

    local c=e:GetHandler()

    if chk==0 then

        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(
                e,
                0,
                POS_FACEUP,
                tp,
                false,
                false
            )
            and Duel.IsExistingMatchingCard(
                s.spfilter,
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
        c,
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

    local g=Duel.GetMatchingGroup(
        s.spfilter,
        1-tp,
        LOCATION_ONFIELD,
        0,
        nil
    )

    if #g==0 then
        return
    end

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

    if #dg>0 then
        Duel.Destroy(
            dg,
            REASON_EFFECT
        )
    end

end


--------------------------------------------------
-- EFFECT 3
--------------------------------------------------

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    -- Must have been sent by a card effect
    if not c:IsReason(REASON_EFFECT) then
        return false
    end

    -- Not during Damage Step
    if Duel.IsDamageCalculation() then
        return false
    end

    return true

end


--------------------------------------------------
-- Fusion Monster filter
--------------------------------------------------

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


--------------------------------------------------
-- Fusion target
--------------------------------------------------

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


--------------------------------------------------
-- Fusion operation
--------------------------------------------------

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

    --------------------------------------------------
    -- Build possible Fusion Materials
    --------------------------------------------------

    local mg=Duel.GetFusionMaterial(tp)

    -- Mirella herself is in the GY
    if c:IsLocation(LOCATION_GRAVE)
        and c:IsCanBeFusionMaterial(fc)
    then
        mg:AddCard(c)
    end

    --------------------------------------------------
    -- Use the standard EDOPro Fusion procedure
    --------------------------------------------------

    local mat=nil

    if fc.GetMaterial then
        mat=fc:GetMaterial()
    end

    --------------------------------------------------
    -- Check whether the selected Fusion Monster
    -- can actually use the available materials.
    --------------------------------------------------

    if not fc:CheckFusionMaterial(
        mg,
        nil,
        tp
    ) then
        return
    end

    --------------------------------------------------
    -- Let the engine perform the Fusion selection.
    --------------------------------------------------

    local sg=fc:SelectFusionMaterial(
        tp,
        mg,
        nil,
        tp
    )

    if not sg or #sg==0 then
        return
    end

    --------------------------------------------------
    -- Fusion Summon
    --------------------------------------------------

    if Duel.SpecialSummon(
        fc,
        SUMMON_TYPE_FUSION,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )==0 then
        return
    end

    --------------------------------------------------
    -- Put all selected Fusion Materials
    -- on the bottom of the Deck.
    --------------------------------------------------

    Duel.SendtoDeck(
        sg,
        nil,
        SEQ_DECKBOTTOM,
        REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
    )

end