-- Whirlwind Rise - Feather Storm
local s,id=GetID()
function s.initial_effect(c)
	--Act
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x33}
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetCounter(tp,LOCATION_ONFIELD,0,0x10)
	if chk==0 then
		if ct<5 then return false end
		if ct>=5 and ct<=9 then
			return s.syncheck(e,tp)
		elseif ct>=10 and ct<=19 then
			return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
		elseif ct>=20 then
			return true
		end
		return false
	end
	if ct>=20 then
		e:SetCategory(0)
	elseif ct>=10 and ct<=19 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	elseif ct>=5 and ct<=9 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_GRAVE)
	end
end
function s.tfilter(c,e,tp)
	return c:IsSetCard(0x33) and c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.ntfilter(c,e,tp)
	return c:IsSetCard(0x33) and not c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.syncheck(e,tp)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return false end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return false end
	local g1=Duel.GetMatchingGroup(s.tfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
	local g2=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
	if #g1==0 or #g2==0 then return false end
	for tc1 in aux.Next(g1) do
		for tc2 in aux.Next(g2) do
			if tc1~=tc2 then
				local mg=Group.FromCards(tc1,tc2)
				if Duel.IsExistingMatchingCard(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,1,nil,nil,mg) then
					return true
				end
			end
		end
	end
	return false
end
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_SYNCHRO) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_WINGEDBEAST)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetCounter(tp,LOCATION_ONFIELD,0,0x10)
	if ct<5 then return end
	Duel.RemoveCounter(tp,1,0,0x10,ct,REASON_EFFECT)
	local removed=ct 
	if removed>=20 then
		Duel.Win(tp,1)
	elseif removed>=10 and removed<=19 then
		math.ceil(Duel.GetLP(1-tp)/2)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(g,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
			g:GetFirst():CompleteProcedure()
		end
	elseif removed>=5 and removed<=9 then
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
		local g1=Duel.GetMatchingGroup(s.tfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
		local g2=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
		if #g1==0 or #g2==0 then return end
		local valid1=Group.CreateGroup()
		local valid2=Group.CreateGroup()
		for tc1 in aux.Next(g1) do
			for tc2 in aux.Next(g2) do
				if tc1~=tc2 then
					local mg=Group.FromCards(tc1,tc2)
					if Duel.IsExistingMatchingCard(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,1,nil,nil,mg) then
						valid1:AddCard(tc1)
						valid2:AddCard(tc2)
					end
				end
			end
		end
		if #valid1==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg1=valid1:Select(tp,1,1,nil)
		local tc1=tg1:GetFirst()
		local valid2_filtered=valid2:Filter(function(c,tc1)
			local mg=Group.FromCards(c,tc1)
			return c~=tc1 and Duel.IsExistingMatchingCard(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,1,nil,nil,mg)
		end,nil,tc1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg2=valid2_filtered:Select(tp,1,1,nil)
		local tc2=tg2:GetFirst()
		local sg=Group.FromCards(tc1,tc2)
		if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==2 then
			local syng=Duel.GetMatchingGroup(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,nil,nil,sg)
			if #syng>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local syncard=syng:Select(tp,1,1,nil):GetFirst()
				if syncard then
					Duel.SynchroSummon(tp,syncard,nil,sg)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					syncard:RegisterEffect(e1)
				end
			end
		end
	end
end
