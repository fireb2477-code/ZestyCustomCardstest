-- Red-Eyes Black Metal Dragon Sword
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter)
	-- Must be Special Summoned with "The Claw of Hermos"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	-- Special Summon 2
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end
s.listed_names={46232525}
s.listed_series={0x3b}
function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp)
end
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(46232525)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x3b) and c:IsType(TYPE_MONSTER) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,2,nil,e,tp)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCountFromEx(tp,tp,nil,nil)<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,2,2,nil,e,tp)
	if #g==2 and Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)==2 then
		if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
			local eqg=g:Select(tp,1,1,nil)
			local tc=eqg:GetFirst()
			if tc and Duel.Equip(tp,c,tc) then
				-- Equip limit
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_EQUIP_LIMIT)
				e1:SetValue(s.eqlimit)
				e1:SetLabelObject(tc)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e1)
				-- Indes
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_EQUIP)
				e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
				e2:SetValue(1)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e2)
				-- Cannot be targeted
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_EQUIP)
				e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
				e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
				e3:SetValue(1)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e3)
			end
		end
	end
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end
