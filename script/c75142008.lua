-- Rage of Red-Eyes Souls
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_ATKCHANGE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={74677422}
s.listed_series={0x3b}
function s.spfilter(c,e,tp)
	return c:IsCode(74677422) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.ffilter(c,e,tp)
	return c:IsSetCard(0x3b) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
	if #g==0 then return end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=g:Select(tp,ft,ft,nil)
	end
	local ct=Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	if ct>0 then
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
			e1:SetValue(LOCATION_REMOVED)
			tc:RegisterEffect(e1)
		end
		Duel.BreakEffect()
		-- 1+: Fusion Summon
		local fusg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		local cg1=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		local can_fusion = false
		for tc in aux.Next(cg1) do
			if tc:CheckFusionMaterial(fusg,nil,tp) then
				can_fusion = true
				break
			end
		end
		if can_fusion then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=cg1:FilterSelect(tp,function(c) return c:CheckFusionMaterial(fusg,nil,tp) end,1,1,nil)
			local tc=sg:GetFirst()
			if tc then
				local mat=Duel.SelectFusionMaterial(tp,tc,fusg,nil,tp)
				tc:SetMaterial(mat)
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
		-- 2+: ATK Buff
		if ct>=2 then
			local count=Duel.GetMatchingGroupCount(function(c) return c:IsCode(74677422) and c:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
			if count>0 then
				local upg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
				for tc in aux.Next(upg) do
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_UPDATE_ATTACK)
					e1:SetValue(count*700)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
				end
			end
		end
		-- 3+: Damage
		if ct>=3 then
			local count=Duel.GetMatchingGroupCount(function(c) return c:IsSetCard(0x3b) and c:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
			if count>0 then
				Duel.Damage(1-tp,count*700,REASON_EFFECT)
			end
		end
	end
end
