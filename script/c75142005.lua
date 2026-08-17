-- Red-Eyes's Transformation
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x3b}
function s.mat_fil(c)
	return c:IsMonster() and c:IsLevelAbove(1) and (c:IsLocation(LOCATION_HAND) or c:IsAbleToGrave())
end
function s.ritual_fil(c,e,tp,max_lv)
	return c:IsSetCard(0x3b) and c:IsType(TYPE_RITUAL) and c:IsMonster() 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
		and c:GetLevel()<=max_lv
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		local mg=Duel.GetMatchingGroup(s.mat_fil,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
		local sum=0
		for tc in aux.Next(mg) do sum=sum+tc:GetLevel() end
		return Duel.IsExistingMatchingCard(s.ritual_fil,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,sum)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_GRAVE)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local mg=Duel.GetMatchingGroup(s.mat_fil,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	local sum=0
	for tc in aux.Next(mg) do sum=sum+tc:GetLevel() end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.ritual_fil,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,sum)
	local tc=tg:GetFirst()
	if tc then
		local lv=tc:GetLevel()
		local mat=Group.CreateGroup()
		local current_lv=0
		while current_lv<lv do
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TRIBUTE)
			local sg=mg:FilterSelect(tp,function(c) return not mat:IsContains(c) end,1,1,nil)
			if #sg==0 then break end
			mat:Merge(sg)
			current_lv=current_lv+sg:GetFirst():GetLevel()
		end
		if current_lv<lv then return end
		tc:SetMaterial(mat)
		local mat_hand=mat:Filter(Card.IsLocation,nil,LOCATION_HAND)
		local mat_deck=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
		if #mat_hand>0 then
			Duel.Release(mat_hand,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
		end
		if #mat_deck>0 then
			Duel.SendtoGrave(mat_deck,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
		end
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
			local eqg=Duel.GetMatchingGroup(s.eqfilter,tp,LOCATION_GRAVE,0,nil)
			if #eqg>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
				local eqc=eqg:Select(tp,1,1,nil):GetFirst()
				if eqc then
					Duel.Equip(tp,eqc,tc)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_EQUIP_LIMIT)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					e1:SetValue(s.eqlimit)
					e1:SetLabelObject(tc)
					eqc:RegisterEffect(e1)
				end
			end
		end
	end
end
function s.eqfilter(c)
	return c:IsSetCard(0x3b) and c:IsMonster() and not c:IsForbidden()
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end
