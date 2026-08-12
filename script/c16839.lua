-- Fallen of Ecclesia
local s,id=GetID()
function s.initial_effect(c)
    -- 1. Special Summon from Hand or GY
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- 2. Search or Recover "Fallen of Albaz" or a card that mentions it
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    -- 3. Fusion Substitute (áp dụng cho quái thú Dung hợp có nhắc đến "Fallen of Albaz")
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_FUSION_SUBSTITUTE)
    e4:SetValue(s.subval)
    c:RegisterEffect(e4)

    -- 4. Granted Effect cho Fusion Monster
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_BE_MATERIAL)
    e5:SetCondition(s.efcon)
    e5:SetOperation(s.efop)
    c:RegisterEffect(e5)
end

s.listed_names={55273561,68468459}

-- E1 Logic: Check opponent Extra Deck monsters
function s.spfilter(c)
    return c:IsFaceup() and c:IsSummonLocation(LOCATION_EXTRA)
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,0,LOCATION_MZONE,1,nil)
end

-- E2 Logic: Search Albaz or mentions Albaz
function s.thfilter(c)
    return (c:IsCode(68468459) or c:ListsCode(68468459)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- E4 Logic: Fusion Substitute
function s.subval(e,c)
    if not c then return true end
    return c:ListsCode(68468459)
end

-- E5 Logic: Granted Quick Effect
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_FUSION and rc:ListsCode(68468459)
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
    if not rc:IsType(TYPE_EFFECT) then
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_ADD_TYPE)
        e2:SetValue(TYPE_EFFECT)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        rc:RegisterEffect(e2,true)
    end
end

-- Quick Effect (Granted): Negate and Force Banish from Deck
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainDisablable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateEffect(ev) then
        local typ=re:GetActiveType() & 0x7 
        local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,1-tp,LOCATION_DECK,0,nil)
        local filter=function(c,t) return c:IsType(t) end
        
        if g:IsExists(filter,1,nil,typ) then
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_REMOVE)
            local sg=g:FilterSelect(1-tp,filter,1,1,nil,typ)
            if #sg>0 then
                Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end
