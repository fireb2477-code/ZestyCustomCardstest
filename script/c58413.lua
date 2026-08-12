-- Witchcrafter Magitech Schmietta
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Nguyên liệu dung hợp: 1 FIRE "Witchcrafter" monster + 1 Spellcaster monster
    Fusion.AddProcMix(c,true,true,s.mfilter1,s.mfilter2)
    
    -- 1. Khi Special Summoned: Triệu hồi hoặc lấy 1 Witchcrafter từ Deck, sau đó có thể Set 1 Witchcrafter Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)
    
    -- 2. Fusion Summon 1 Witchcrafter từ Extra Deck dùng nguyên liệu từ Deck + trao hiệu ứng
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.fustg)
    e2:SetOperation(s.fusop)
    c:RegisterEffect(e2)
end

s.listed_series={0x128}

-- Filter Fusion Material
function s.mfilter1(c,fc,sumtype,tp)
    return c:IsAttribute(ATTRIBUTE_FIRE,fc,sumtype,tp) and c:IsSetCard(0x128,fc,sumtype,tp)
end
function s.mfilter2(c,fc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp)
end

-- E1 Logic
function s.thfilter(c,e,tp)
    if not (c:IsSetCard(0x128) and c:IsMonster()) then return false end
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    return c:IsAbleToHand() or (ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.setfilter(c)
    return c:IsSetCard(0x128) and c:IsSpell() and c:IsSSetable()
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc then
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        local b1=tc:IsAbleToHand()
        local b2=ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
        local op=0
        if b1 and b2 then
            op=Duel.SelectOption(tp,1190,1152) -- 1190: Add to hand, 1152: Special Summon
        elseif b1 then
            op=0
        else
            op=1
        end
        
        local success=false
        if op==0 then
            if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
                Duel.ConfirmCards(1-tp,tc)
                success=true
            end
        else
            if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
                success=true
            end
        end
        
        -- Set 1 Witchcrafter Spell từ Deck hoặc GY
        if success and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
            and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
            if #sg>0 then
                Duel.SSet(tp,sg)
            end
        end
    end
end

-- E2 Logic (Fusion từ Deck & Ban trao hiệu ứng)
function s.fusfilter(c,e,tp,mg)
    return c:IsType(TYPE_FUSION) and c:IsSetCard(0x128)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(mg,nil,tp)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_DECK,0,nil)
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local mg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_DECK,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
    local tc=g:GetFirst()
    if tc then
        local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
        tc:SetMaterial(mat)
        Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
        Duel.BreakEffect()
        if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
            tc:CompleteProcedure()
            
            -- Trao hiệu ứng mới cho quái thú vừa Fusion Summon
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetDescription(aux.Stringid(id,2))
            e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
            e1:SetType(EFFECT_TYPE_IGNITION)
            e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
            e1:SetRange(LOCATION_MZONE)
            e1:SetCountLimit(1)
            e1:SetTarget(s.granttg)
            e1:SetOperation(s.grantop)
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
end

-- Hiệu ứng được trao (Granted Effect: Target tới 2 Spellcaster từ GY để Special Summon)
function s.spfilter_g(c,e,tp)
    return c:IsRace(RACE_SPELLCASTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.granttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter_g(chkc,e,tp) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.spfilter_g,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter_g,tp,LOCATION_GRAVE,0,1,math.min(ft,2),nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
end
function s.grantop(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        if #g>ft or (#g>1 and Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            g=g:Select(tp,1,1,nil)
        end
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end