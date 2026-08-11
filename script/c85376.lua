--Masked HERO Tri-breaker
local s,id=GetID()

function s.initial_effect(c)
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
	-- If Special Summoned by its own procedure:
	-- Banish 1 "HERO" monster from your GY
	-- OR send this card to the GY
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
	-- Negate opponent's card/effect, then destroy it
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
	-- Once per turn
	-- Banish any number of "Masked HERO" monsters
	-- from your GY and gain 300 ATK for each
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
-- "Masked HERO" monsters
-- NO Fusion Monster requirement
---------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0xA008)
		and c:IsMonster()
		and c:IsCanBeFusionMaterial(fc)
end


---------------------------------------------------
-- Check different Attributes
---------------------------------------------------

function s.checkmaterials(g)
	if #g~=3 then
		return false
	end

	local tc1=g:GetFirst()
	local tc2=g:GetNext()
	local tc3=g:GetNext()

	if not tc1 or not tc2 or not tc3 then
		return false
	end

	local a1=tc1:GetAttribute()
	local a2=tc2:GetAttribute()
	local a3=tc3:GetAttribute()

	return a1~=a2
		and a1~=a3
		and a2~=a3
end


---------------------------------------------------
-- Alternative Special Summon
---------------------------------------------------

function s.spfilter(c)
	return c:IsSetCard(0xA008)
		and c:IsMonster()
		and c:IsAbleToRemove()
end


function s.spcon(e,c)
	if c==nil then
		return true
	end

	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	return Duel.GetLocationCountFromEx(
		e:GetHandlerPlayer(),
		e:GetHandlerPlayer(),
		c
	)>0
end


---------------------------------------------------
-- Check whether 3 valid materials exist
---------------------------------------------------

function s.checkspmaterials(tp)
	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil
	)

	if #g<3 then
		return false
	end

	for tc1 in aux.Next(g) do
		local g2=g:Clone()
		g2:RemoveCard(tc1)

		for tc2 in aux.Next(g2) do
			if tc2:GetAttribute()~=tc1:GetAttribute() then

				local g3=g2:Clone()
				g3:RemoveCard(tc2)

				for tc3 in aux.Next(g3) do
					if tc3:GetAttribute()~=tc1:GetAttribute()
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
-- Alternative Summon Target
---------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.checkspmaterials(tp)
	end

	return true
end


---------------------------------------------------
-- Alternative Summon Operation
---------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_EXTRA,
		0,
		nil
	)

	if #g<3 then
		return
	end

	local sg=Group.CreateGroup()

	---------------------------------------------------
	-- Select first material
	---------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc=g:Select(tp,1,1,nil):GetFirst()

	if not tc then
		return
	end

	sg:AddCard(tc)
	g:RemoveCard(tc)


	---------------------------------------------------
	-- Select second material
	---------------------------------------------------

	local g2=g:Filter(
		function(mc,first)
			return mc:GetAttribute()~=first:GetAttribute()
		end,
		nil,
		tc
	)

	if #g2==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc2=g2:Select(tp,1,1,nil):GetFirst()

	if not tc2 then
		return
	end

	sg:AddCard(tc2)
	g:RemoveCard(tc2)


	---------------------------------------------------
	-- Select third material
	---------------------------------------------------

	local g3=g:Filter(
		function(mc,first,second)
			return mc:GetAttribute()~=first:GetAttribute()
				and mc:GetAttribute()~=second:GetAttribute()
		end,
		nil,
		tc,
		tc2
	)

	if #g3==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local tc3=g3:Select(tp,1,1,nil):GetFirst()

	if not tc3 then
		return
	end

	sg:AddCard(tc3)


	---------------------------------------------------
	-- Banish all 3 materials
	---------------------------------------------------

	if #sg~=3 then
		return
	end

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_MATERIAL+REASON_FUSION+REASON_COST
	)

	if ct~=3 then
		return
	end


	---------------------------------------------------
	-- IMPORTANT:
	-- Mark that Tri-breaker was summoned by
	-- its own alternative procedure.
	--
	-- RESET_TOFIELD is intentionally removed.
	---------------------------------------------------

	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,
		0,
		1
	)
end


---------------------------------------------------
-- End Phase condition
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:GetFlagEffect(id)>0
		and c:IsFaceup()
		and c:IsLocation(LOCATION_MZONE)
end


---------------------------------------------------
-- HERO filter
--
-- This is intentionally 0x8:
-- "HERO", NOT specifically "Masked HERO"
---------------------------------------------------

function s.herofilter(c)
	return c:IsSetCard(0x8)
		and c:IsMonster()
		and c:IsAbleToRemove()
end


---------------------------------------------------
-- End Phase Target
---------------------------------------------------

function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	local canbanish=Duel.IsExistingMatchingCard(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)

	local cangy=c:IsAbleToGrave()

	if chk==0 then
		return canbanish or cangy
	end

	---------------------------------------------------
	-- Operation information
	---------------------------------------------------

	if canbanish then
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			nil,
			1,
			tp,
			LOCATION_GRAVE
		)
	end

	if cangy then
		Duel.SetPossibleOperationInfo(
			0,
			CATEGORY_TOGRAVE,
			c,
			1,
			tp,
			LOCATION_MZONE
		)
	end
end


---------------------------------------------------
-- End Phase Operation
---------------------------------------------------

function s.epop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	local canbanish=Duel.IsExistingMatchingCard(
		s.herofilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)

	local cangy=c:IsAbleToGrave()

	---------------------------------------------------
	-- Both choices available
	---------------------------------------------------

	if canbanish and cangy then

		local op=Duel.SelectEffect(
			tp,
			{true,aux.Stringid(id,0)},
			{true,aux.Stringid(id,1)}
		)

		---------------------------------------------------
		-- Banish 1 HERO
		---------------------------------------------------

		if op==1 then

			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_REMOVE
			)

			local g=Duel.SelectMatchingCard(
				tp,
				s.herofilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				1,
				nil
			)

			if #g>0 then
				Duel.Remove(
					g,
					POS_FACEUP,
					REASON_EFFECT
				)
			end

		---------------------------------------------------
		-- Send Tri-breaker to GY
		---------------------------------------------------

		else
			Duel.SendtoGrave(
				c,
				REASON_EFFECT
			)
		end

		return
	end


	---------------------------------------------------
	-- Only HERO available
	---------------------------------------------------

	if canbanish then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.herofilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			1,
			nil
		)

		if #g>0 then
			Duel.Remove(
				g,
				POS_FACEUP,
				REASON_EFFECT
			)
		end

		return
	end


	---------------------------------------------------
	-- Only sending Tri-breaker to GY is possible
	---------------------------------------------------

	if cangy then
		Duel.SendtoGrave(
			c,
			REASON_EFFECT
		)
	end
end


---------------------------------------------------
-- Quick Effect
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

	if re:GetHandler():IsDestructable()
	and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			eg,
			1,
			0,
			0
		)
	end
end


function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()

		if rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then
			Duel.Destroy(
				rc,
				REASON_EFFECT
			)
		end
	end
end


---------------------------------------------------
-- Banish any number of Masked HERO
--
-- IMPORTANT:
-- This uses 0xA008 because the text specifically
-- says "Masked HERO".
---------------------------------------------------

function s.atkfilter(c)
	return c:IsSetCard(0xA008)
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