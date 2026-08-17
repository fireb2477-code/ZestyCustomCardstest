-- Red-Eyes Darkflare Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- Cannot target
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	-- Damage
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end
function s.cfilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON) and c:IsAbleToRemoveAsCost()
		and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,e:GetHandler())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.tgtg(e,c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local dmg=0
	for tc in aux.Next(eg) do
		if tc:IsPreviousLocation(LOCATION_MZONE) and tc:IsAttribute(ATTRIBUTE_DARK) and tc:IsRace(RACE_DRAGON) then
			local atk=tc:GetBaseAttack()
			if atk>0 then
				dmg = dmg + math.floor(atk / 2)
			end
		end
	end
	if dmg>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Damage(tp,dmg,REASON_EFFECT,true)
		Duel.Damage(1-tp,dmg,REASON_EFFECT,true)
		Duel.RDComplete()
	end
end
