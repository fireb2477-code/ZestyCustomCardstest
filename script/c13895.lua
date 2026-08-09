--Tearlaments Mirella
local s,id=GetID()

function s.initial_effect(c)
    ---------------------------------------------------
    -- 1. Add "Tearlaments" card from Deck to hand
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- 2. Quick Effect: Special Summon itself + destroy
    --    if opponent Special Summons a monster
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
    -- 3. If sent to GY by card effect:
    --    Fusion Summon
    ---------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.fuscon)
    e3:SetTarget(s.fustg)
    e3:SetOperation(s.fusop)
    c:RegisterEffect(e3)
end

---------------------------------------------------
-- Effect 1
---------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsDiscardable()
    end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

function s.thfilter(c)
    return c:IsSetCard(0x182)
        and c:IsType(TYPE_SPELL+TYPE_TRAP)
        and c:IsAbleToHand()
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
    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_ATOHAND
    )

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
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

---------------------------------------------------
-- Effect 2
---------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(
                e,
                0,
                tp,
                false,
                false
            )
            and Duel.IsExistingMatchingCard(
                Card.IsAbleToGrave,
                tp,
                0,
                LOCATION_ONFIELD,
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
        Card.IsAbleToGrave,
        tp,
        0,
        LOCATION_ONFIELD,
        nil
    )

    if #g>0 then
        Duel.Hint(
            HINT_SELECTMSG,
            tp,
            HINTMSG_DESTROY
        )

        local tc=g:Select(tp,1,1,nil):GetFirst()

        if tc then
            Duel.Destroy(
                tc,
                REASON_EFFECT
            )
        end
    end
end

---------------------------------------------------
-- Effect 3
---------------------------------------------------

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if not eg:IsContains(c) then
        return false
    end

    -- Must be sent by card effect
    if not re then
        return false
    end

    -- Not during Damage Step
    if Duel.IsDamageStep() then
        return false
    end

    return c:IsReason(REASON_EFFECT)
end

---------------------------------------------------
-- Fusion filter
---------------------------------------------------

function s.fusfilter(c,e,tp)
    return c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(
            e,
            SUMMON_TYPE_FUSION,
            tp,
            false,
            false
        )
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.fusfilter,
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

---------------------------------------------------
-- Fusion materials
---------------------------------------------------

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if not c:IsRelateToEffect(e) then
        return
    end

    local mg=Duel.GetFusionMaterial(tp)

    local chkf=Card.IsCanBeFusionMaterial

    local sg=Duel.SelectMatchingCard(
        tp,
        s.fusfilter,
        tp,
        LOCATION_EXTRA,
        0,
        1,
        1,
        nil,
        e,
        tp
    )

    local fc=sg:GetFirst()

    if not fc then
        return
    end

    -- Try normal Fusion procedure
    local mat=fc:GetMaterial()

    if not mat then
        return
    end

    local fmat=Duel.SelectFusionMaterial(
        tp,
        fc,
        mg,
        tp
    )

    if not fmat or #fmat==0 then
        return
    end

    -- Mirella must be included as material
    if not fmat:IsContains(c) then
        return
    end

    Duel.SendtoDeck(
        fmat,
        nil,
        SEQ_DECKBOTTOM,
        REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
    )

    Duel.SpecialSummon(
        fc,
        SUMMON_TYPE_FUSION,
        tp,
        tp,
        false,
        false,
        POS_FACEUP
    )
end