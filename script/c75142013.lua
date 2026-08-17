-- Red-Eyes's Nest
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	-- Quick-like Effect while face-up
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetHintTiming(0,TIMING_END_PHASE)
	e2:SetTarget(s.target2)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
s.listed_names={74677422}
s.listed_series={0x3b}
function s.is_listed(c, code)
	if c:IsCode(code) then return true end
	if c.listed_names then
		for _,v in pairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end
function s.spfilter(c,e,tp)
	return (c:IsCode(74677422) or c:IsCode(89631139)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.setfilter(c,tp)
	if not (c:IsSpellTrap() and c:IsSSetable() and (c:IsSetCard(0x3b) or s.is_listed(c,74677422) or s.is_listed(c,89631139))) then return false end
	local gy=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,LOCATION_GRAVE,0,nil)
	for gc in aux.Next(gy) do
		if gc:IsCode(c:GetCode()) then return false end
	end
	return true
end
function s.lv7filter(c)
	return c:IsSetCard(0x3b) and c:IsLevelAbove(7) and c:IsFaceup()
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	local b2=Duel.IsExistingMatchingCard(s.lv7filter,tp,LOCATION_MZONE,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,tp)
	if (b1 or b2) and Duel.GetFlagEffect(tp,id)==0 and Duel.SelectYesNo(tp,94) then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		Duel.SetTargetParam(1)
		if b1 and not b2 then
			Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
		end
	else
		Duel.SetTargetParam(0)
	end
end
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	local b2=Duel.IsExistingMatchingCard(s.lv7filter,tp,LOCATION_MZONE,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,tp)
	if chk==0 then return (b1 or b2) and Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	Duel.SetTargetParam(1)
	if b1 and not b2 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)~=1 then return end
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	local b2=Duel.IsExistingMatchingCard(s.lv7filter,tp,LOCATION_MZONE,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil,tp)
	if not b1 and not b2 then return end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=0
	else
		op=1
	end
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil,tp)
		if #g>0 then
			Duel.SSet(tp,g)
		end
	end
end
