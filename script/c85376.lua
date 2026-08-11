--Masked HERO Tri-breaker
local s,id=GetID()

local SET_MASKED_HERO=0xA008

function s.initial_effect(c)
	---------------------------------------------------
	-- Fusion Monster
	---------------------------------------------------
	c:EnableReviveLimit()

	-- 3 "Masked HERO" monsters
	Fusion.AddProcMix(c,true,true,
		s.matfilter,
		s.matfilter,
		s.matfilter
	)

	---------------------------------------------------
	-- Alternative Special Summon
	-- Banish 3 "Masked HERO" monsters with different
	-- Attributes from your GY and/or Extra Deck
	---------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	---------------------------------------------------
	-- End Phase
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.epcon)
	e1:SetTarget(s.eptg)
	e1:SetOperation(s.epop)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Quick Effect
	-- Negate activation, then destroy that card
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Banish "Masked HERO" monsters from GY
	-- Gain 300 ATK for each
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end


---------------------------------------------------
-- Fusion Material
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_MASKED_HERO)
		and c:IsMonster()
		and c:IsCanBeFusionMaterial(fc,sumtype,tp)
end


---------------------------------------------------
-- Check 3 different Attributes
---------------------------------------------------

function s.matcheck(g)
	if #g~=3 then
		return false
	end

	local tc1=g:GetFirst()
	local tc2=g:GetNext()
	local tc3=g:GetNext()

	if not tc1 or not tc2 or not tc3 then
		return false
	end

	return tc1:GetAttribute()~=tc2:GetAttribute()
		and tc1:GetAttribute()~=tc3:GetAttribute()
		and tc2:GetAttribute()~=tc3:GetAttribute()
end


---------------------------------------------------
-- Filter for Alternative Summon
---------------------------------------------------

function s.spfilter(c,sc)
	return c~=sc
		and c:IsSetCard(SET_MASKED_HERO)
		and c:IsMonster()
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- Check whether 3 valid materials exist
---------------------------------------------------

function s.checkmaterials(tp,c)
	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil,
		c
	)

	if #g<3 then
		return false
	end

	---------------------------------------------------
	-- Check every possible combination of 3 cards
	---------------------------------------------------
	for tc1 in aux.Next(g) do

		for tc2 in aux.Next(g) do

			if tc2~=tc1
			and tc1:GetAttribute()~=tc2:GetAttribute()
			then

				for tc3 in aux.Next(g) do

					if tc3~=tc1
					and tc3~=tc2
					and tc3:GetAttribute()~=tc1:GetAttribute()
					and tc3:GetAttribute()~=tc2:GetAttribute()
					then
						return true
					end

				end
			end

		end

	end

	return false
end


---------------------------------------------------
-- Alternative Special Summon condition
---------------------------------------------------

function s.spcon(e,c)
	if c==nil then
		return true
	end

	local tp=c:GetControler()

	---------------------------------------------------
	-- Must have a place to Special Summon
	---------------------------------------------------
	if Duel.GetLocationCountFromEx(tp,tp,c)<=0 then
		return false
	end

	---------------------------------------------------
	-- Must have 3 different-Attribute Masked HERO
	---------------------------------------------------
	return s.checkmaterials(tp,c)
end


---------------------------------------------------
-- Select materials
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil,
		c
	)

	if chk==0 then
		return #g>=3
	end

	---------------------------------------------------
	-- Select 3 cards with different Attributes
	---------------------------------------------------

	local sg=aux.SelectUnselectGroup(
		g,
		e,
		tp,
		3,
		3,
		function(g)
			return s.matcheck(g)
		end,
		1,
		tp,
		HINTMSG_REMOVE
	)

	if #sg~=3 then
		return false
	end

	---------------------------------------------------
	-- Store selected cards as targets
	---------------------------------------------------
	Duel.SetTargetCard(sg)
	sg:KeepAlive()

	return true
end


---------------------------------------------------
-- Alternative Special Summon operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)

	local g=Duel.GetTargetCards(e)

	if not g or #g~=3 then
		return
	end

	---------------------------------------------------
	-- Re-check materials
	---------------------------------------------------

	local rg=g:Filter(
		function(tc,sc)
			return tc~=sc
				and tc:IsSetCard(SET_MASKED_HERO)
				and tc:IsMonster()
				and tc:IsAbleToRemove()
				and tc:IsLocation(LOCATION_GRAVE+LOCATION_EXTRA)
		end,
		nil,
		c
	)

	if #rg~=3 then
		return
	end

	if not s.matcheck(rg) then
		return
	end

	---------------------------------------------------
	-- Banish the 3 materials
	---------------------------------------------------

	if Duel.Remove(
		rg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION+REASON_COST
	)~=3 then
		return
	end

	---------------------------------------------------
	-- Mark this card as summoned by its own procedure
	---------------------------------------------------

	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD,
		0,
		1
	)

	rg:DeleteGroup()
end


---------------------------------------------------
-- End Phase condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():HasFlagEffect(id)
end


---------------------------------------------------
-- HERO filter
---------------------------------------------------

function s.herofilter(c)
	return c:IsSetCard(0x8)
		and c:IsMonster()
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- End Phase target
---------------------------------------------------

function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.herofilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
		or c:IsAbleToGrave()
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		c,
		1,
		tp,
		LOCATION_MZONE
	)
end


---------------------------------------------------
-- End Phase operation
---------------------------------------------------

function s.epop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	local g=Duel.GetMatchingGroup(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if #g>0 then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local tc=g:Select(
			tp,
			1,
			1,
			nil
		):GetFirst()

		if tc then
			Duel.Remove(
				tc,
				POS_FACEUP,
				REASON_EFFECT
			)
			return
		end
	end

	if c:IsRelateToEffect(e) then
		Duel.SendtoGrave(
			c,
			REASON_EFFECT
		)
	end
end


---------------------------------------------------
-- Negate opponent's activation
---------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp
end


function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.IsChainDisablable(ev)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		eg,
		1,
		0,
		0
	)
end


function s.negop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.NegateActivation(ev) then

		if eg and #eg>0 then
			Duel.Destroy(
				eg,
				REASON_EFFECT
			)
		end

	end
end


---------------------------------------------------
-- ATK gain
---------------------------------------------------

function s.atkfilter(c)

	return c:IsSetCard(SET_MASKED_HERO)
		and c:IsMonster()
		and c:IsAbleToRemove()

end


function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		return Duel.IsExistingMatchingCard(
			s.atkfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)

	end
end


function s.atkop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	local g=Duel.GetMatchingGroup(
		s.atkfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local sg=g:Select(
		tp,
		1,
		# g,
		nil
	)

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT
	)

	if ct>0 then

		local e1=Effect.CreateEffect(c)

		e1:SetType(EFFECT_TYPE_SINGLE)

		e1:SetCode(EFFECT_UPDATE_ATTACK)

		e1:SetValue(ct*300)

		e1:SetReset(
			RESET_EVENT+RESETS_STANDARD_DISABLE
		)

		c:RegisterEffect(e1)

	end
end