-- Masked HERO Death Law
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Giới hạn điều khiển: "You can only control 1 Masked HERO Death Law"
    c:SetUniqueOnField(1,1,id)
    
    -- 1. Must be Special Summoned by banishing 1 "Mask Change" from your hand or face-down field
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    e1:SetValue(SUMMON_TYPE_SPECIAL)
    c:RegisterEffect(e1)
    
    -- 3. Any card sent to your opponent's GY is banished instead
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
    e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0,LOCATION_ALL)
    e2:SetValue(LOCATION_REMOVED)
    e2:SetTarget(s.rmtarget)
    c:RegisterEffect(e2)
    
    -- 4. Gains 200 ATK for each banished card
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)
    
    -- 5. Once while face-up: End Phase banish top of opponent's Deck equal to cards in your GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE+PHASE_END)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.deckrmcon)
    e4:SetTarget(s.deckrmtg)
    e4:SetOperation(s.deckrmop)
    c:RegisterEffect(e4)
    
    -- 6. If this card leaves the field: Special Summon 1 DARK "Masked HERO" from Extra Deck, then Set 1 "Mask Change"
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_LEAVE_FIELD)
    e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
    e5:SetTarget(s.sptg2)
    e5:SetOperation(s.spop2)
    c:RegisterEffect(e5)
end

s.listed_names={21143940} -- Mask Change
s.listed_series={0xa008}  -- Masked HERO

-- E1: Special Summon Procedure
function s.spfilter(c)
    return c:IsCode(21143940) and c:IsAbleToRemoveAsCost()
        and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_ONFIELD) and c:IsFacedown()))
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,nil)
    return aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),0)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,nil)
    local g=aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_REMOVE,nil,nil,true)
    if #g>0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.Remove(g,POS_FACEUP,REASON_COST)
    g:DeleteGroup()
end

-- E3: Banish redirect filter
function s.rmtarget(e,c)
    return c:GetOwner()==1-e:GetHandlerPlayer()
end

-- E4: ATK gain value
function s.atkval(e,c)
    return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_REMOVED,LOCATION_REMOVED)*200
end

-- E5: Banish top deck
function s.deckrmcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetFlagEffect(id)==0
end

function s.deckrmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ct=Duel.GetFieldGroupCount(tp,LOCATION_GRAVE,0)
    if chk==0 then return ct>0 and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=ct end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,1-tp,LOCATION_DECK)
end

function s.deckrmop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
    end
    local ct=Duel.GetFieldGroupCount(tp,LOCATION_GRAVE,0)
    if ct>0 and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=ct then
        local g=Duel.GetDecktopGroup(1-tp,ct)
        if #g>0 then
            Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        end
    end
end

-- E6: Leave field effect
function s.spfilter2(c,e,tp)
    return c:IsSetCard(0xa008) and c:IsAttribute(ATTRIBUTE_DARK)
        and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.setfilter(c)
    return c:IsCode(21143940) and c:IsSSetable()
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCountFromEx(tp)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)>0 then
        local sg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        if #sg>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local setg=sg:Select(tp,1,1,nil)
            Duel.SSet(tp,setg)
        end
    end
end
