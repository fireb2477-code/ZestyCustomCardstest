-- Melodious Grand Theater
local s,id=GetID()
function s.initial_effect(c)
    -- Activate: You can only activate 1 "Melodious Grand Theater" per turn.
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.acttg)
    e1:SetOperation(s.actop)
    c:RegisterEffect(e1)
    
    -- Floodgate: Opponent cannot activate monster effects in the hand
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(0,1)
    e2:SetCondition(s.actcon)
    e2:SetValue(s.actlimit)
    c:RegisterEffect(e2)
    
    -- Grant Quick Effect to a "Melodious" Fusion Monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCondition(s.grantcon)
    e3:SetTarget(s.granttg)
    e3:SetOperation(s.grantop)
    c:RegisterEffect(e3)
    
    -- Fusion Summon a "Melodious" Fusion Monster with 5000 ATK
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.fscon)
    e4:SetTarget(s.fstg)
    e4:SetOperation(s.fsop)
    c:RegisterEffect(e4)
end

s.listed_series={0x9b}

-- E1 Logic: Optional Search on Activation
function s.thfilter(c)
    return c:IsSetCard(0x9b) and (c:IsMonster() or c:IsSpellTrap()) and c:IsAbleToHand()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:Select(tp,1,1,nil)
        if #sg>0 then
            Duel.SendtoHand(sg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,sg)
        end
    end
end

-- E2 Logic: Floodgate
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x9b) and c:IsMonster()
end
function s.actcon(e)
    return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.actlimit(e,re,tp)
    return re:IsActiveType(TYPE_MONSTER) and re:GetActivateLocation()==LOCATION_HAND
end

-- E3 Logic: Grant Effect on sent to GY
function s.grantcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_FZONE) and c:IsPreviousPosition(POS_FACEUP)
end
function s.gtgfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x9b) and c:IsType(TYPE_FUSION)
end
function s.granttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.gtgfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.gtgfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.gtgfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.grantop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        -- Granted Quick Effect
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetCategory(CATEGORY_DISABLE+CATEGORY_SPECIAL_SUMMON)
        e1:SetType(EFFECT_TYPE_QUICK_O)
        e1:SetCode(EVENT_CHAINING)
        e1:SetRange(LOCATION_MZONE)
        e1:SetCountLimit(1)
        e1:SetCondition(s.negcon)
        e1:SetTarget(s.negtg)
        e1:SetOperation(s.negop)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1,true)
        if not tc:IsType(TYPE_EFFECT) then
            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_ADD_TYPE)
            e2:SetValue(TYPE_EFFECT)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e2,true)
        end
    end
end

-- E3 Granted Effect Logic: Negate and Summon
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainDisablable(ev)
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x9b) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_EXTRA+LOCATION_GRAVE,0,nil,e,tp)
        if #g>0 and Duel.GetLocationCountFromEx(tp)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=g:Select(tp,1,1,nil)
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

-- E4 Logic: Fusion Summon
function s.fscon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetLP(tp) < Duel.GetLP(1-tp)
end
function s.mfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial() and c:IsAbleToDeck()
        and (c:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end
function s.fsfilter(c,e,tp,m)
    return c:IsSetCard(0x9b) and c:IsType(TYPE_FUSION) and c:GetAttack()==5000
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(m,nil,tp)
end
function s.fstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        return Duel.IsExistingMatchingCard(s.fsfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.fsop(e,tp,eg,ep,ev,re,r,rp)
    local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.fsfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
    local tc=g:GetFirst()
    if tc then
        local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
        tc:SetMaterial(mat)
        
        -- Xác nhận nếu có bài úp bị đem làm nguyên liệu từ banishment/sân
        if mat:IsExists(Card.IsFacedown,1,nil) then
            local cg=mat:Filter(Card.IsFacedown,nil)
            Duel.ConfirmCards(1-tp,cg)
        end
        
        Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
        Duel.BreakEffect()
        if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
            tc:CompleteProcedure()
            
            -- Grant Direct Attack
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetDescription(3211) -- "Can attack directly" Client Hint
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DIRECT_ATTACK)
            e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CLIENT_HINT)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
        end
    end
end
