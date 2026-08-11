--Masked HERO Tri-breaker
local s,id=GetID()

function s.initial_effect(c)

	---------------------------------------------------
	-- Constants
	---------------------------------------------------
	local HERO=0x8
	local MASKED_HERO=0xA008

	---------------------------------------------------
	-- Fusion Summon
	-- 3 "Masked HERO" monsters with different Attributes
	---------------------------------------------------
	c:EnableReviveLimit()

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
	-- Negate opponent's activation, then destroy it
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
	-- Banish any number of "Masked HERO" monsters
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
-- 3 Masked HERO monsters
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0xA008)
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Alternative Special Summon filter
---------------------------------------------------

function s.spfilter(c,sc)
	return c~=sc
		and c:IsSetCard(0xA008)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- Check whether 3 valid materials exist
-- They must have different Attributes.
---------------------------------------------------

function s.checkmaterials(tp,sc)

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		sc
	)

	if #g<3 then
		return false
	end

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

	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	local tp=e:GetHandlerPlayer()

	---------------------------------------------------
	-- Check Extra Monster Zone / available zone
	---------------------------------------------------

	if Duel.GetLocationCountFromEx(
		tp,
		tp,
		c
	)<=0 then
		return false
	end

	---------------------------------------------------
	-- Check actual materials
	---------------------------------------------------

	return s.checkmaterials(tp,c)
end


---------------------------------------------------
-- Special Summon target
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return s.checkmaterials(
			tp,
			e:GetHandler()
		)
	end

	return true
end


---------------------------------------------------
-- Alternative Special Summon operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		c
	)

	if #g<3 then
		return
	end


	---------------------------------------------------
	-- Select first material
	---------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc1=g:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not tc1 then
		return
	end

	g:RemoveCard(tc1)


	---------------------------------------------------
	-- Select second material
	---------------------------------------------------

	local g2=g:Filter(
		function(mc,attr)
			return mc:GetAttribute()~=attr
		end,
		nil,
		tc1:GetAttribute()
	)

	if #g2==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc2=g2:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not tc2 then
		return
	end

	g:RemoveCard(tc2)


	---------------------------------------------------
	-- Select third material
	---------------------------------------------------

	local g3=g:Filter(
		function(mc,attr1,attr2)

			local attr=mc:GetAttribute()

			return attr~=attr1
				and attr~=attr2
		end,
		nil,
		tc1:GetAttribute(),
		tc2:GetAttribute()
	)

	if #g3==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc3=g3:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not tc3 then
		return
	end


	---------------------------------------------------
	-- Create material group
	---------------------------------------------------

	local sg=Group.CreateGroup()

	sg:AddCard(tc1)
	sg:AddCard(tc2)
	sg:AddCard(tc3)


	---------------------------------------------------
	-- Banish all 3 materials
	---------------------------------------------------

	if Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION+REASON_COST
	)~=3 then
		return
	end

	---------------------------------------------------
	-- IMPORTANT:
	-- Mark the card BEFORE the procedure finishes.
	--
	-- RESET_STANDARD_DISABLE allows the flag to survive
	-- the Special Summon itself, while still removing it
	-- when the card leaves the field.
	---------------------------------------------------

	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD_DISABLE,
		0,
		1
	)
end


---------------------------------------------------
-- End Phase condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	return c:IsFaceup()
		and c:GetFlagEffect(id)>0
end


---------------------------------------------------
-- HERO filter
--
-- This is HERO in general, NOT Masked HERO only.
---------------------------------------------------

function s.herofilter(c)

	return c:IsSetCard(0x8)
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

	---------------------------------------------------
	-- If HERO exists, both options are possible.
	---------------------------------------------------

	if Duel.IsExistingMatchingCard(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)
	then

		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			nil,
			1,
			tp,
			LOCATION_GRAVE
		)

	end

	---------------------------------------------------
	-- Sending Tri-breaker to GY is also possible.
	---------------------------------------------------

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

	---------------------------------------------------
	-- If HERO exists:
	-- Choose:
	-- 1. Banish 1 HERO
	-- 2. Send Tri-breaker to GY
	---------------------------------------------------

	if #g>0 then

		local opt=Duel.SelectOption(
			tp,
			" Banish 1 HERO from your GY",
			" Send this card to the GY"
		)

		---------------------------------------------------
		-- Option 1: Banish HERO
		---------------------------------------------------

		if opt==0 then

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

			end

			return
		end

		---------------------------------------------------
		-- Option 2: Send Tri-breaker to GY
		---------------------------------------------------

		if c:IsRelateToEffect(e) then

			Duel.SendtoGrave(
				c,
				REASON_EFFECT
			)

		end

		return
	end


	---------------------------------------------------
	-- No HERO in GY:
	-- Automatically send Tri-breaker to GY.
	---------------------------------------------------

	if c:IsRelateToEffect(e) then

		Duel.SendtoGrave(
			c,
			REASON_EFFECT
		)

	end
end


---------------------------------------------------
-- Negate opponent's card/effect
---------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)

	return rp~=tp
		and Duel.IsChainDisablable(ev)
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

		Duel.Destroy(
			eg,
			REASON_EFFECT
		)

	end
end


---------------------------------------------------
-- ATK gain filter
-- ONLY Masked HERO
---------------------------------------------------

function s.atkfilter(c)

	return c:IsSetCard(0xA008)
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- ATK gain target
---------------------------------------------------

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

	return true
end


---------------------------------------------------
-- ATK gain operation
---------------------------------------------------

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


	---------------------------------------------------
	-- Select any number of Masked HERO
	---------------------------------------------------

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


	---------------------------------------------------
	-- Banish
	---------------------------------------------------

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT
	)


	---------------------------------------------------
	-- Gain 300 ATK for each
	---------------------------------------------------

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