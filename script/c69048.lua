--Masked HERO Death Law
local s,id=GetID()

s.listed_names={21143940}
s.listed_series={0x8,0xA008}

function s.initial_effect(c)
	---------------------------------------------------
	-- Special Summon procedure
	-- Must be Special Summoned by banishing
	-- "Mask Change" from your hand or face-down field
	---------------------------------------------------
	c:EnableReviveLimit()

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
	-- You can only control 1
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UNIQUE_CHECK)
	e1:SetUniquePos(1)
	e1:SetUniqueCode(id)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Cards sent to opponent's GY are banished instead
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_ONFIELD)
	e2:SetValue(LOCATION_REMOVED)
	e2:SetTarget(s.rmtg)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Gains 200 ATK for each banished card
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	---------------------------------------------------
	-- Once while face-up on the field:
	-- During the End Phase, banish cards from the
	-- top of opponent's Deck equal to the number
	-- of cards in your GY
	---------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.epcon)
	e4:SetTarget(s.eptg)
	e4:SetOperation(s.epop)
	c:RegisterEffect(e4)

	---------------------------------------------------
	-- If this card leaves the field:
	-- Special Summon 1 DARK "Masked HERO" from
	-- the Extra Deck, ignoring its Summoning conditions
	-- Then Set "Mask Change" from GY or banishment
	---------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOFIELD)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_LEAVE_FIELD)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCondition(s.lvcon)
	e5:SetTarget(s.lvtg)
	e5:SetOperation(s.lvop)
	c:RegisterEffect(e5)
end


---------------------------------------------------
-- Special Summon procedure
---------------------------------------------------

function s.mcfilter(c)
	return c:IsCode(21143940)
		and c:IsAbleToRemove()
end

function s.spcon(e,c)
	if c==nil then return true end
	if not c:IsLocation(LOCATION_EXTRA) then return false end

	local tp=e:GetHandlerPlayer()

	return Duel.GetLocationCountFromEx(tp,tp,nil)>0
		and Duel.IsExistingMatchingCard(
			s.mcfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
		or Duel.IsExistingMatchingCard(
			s.mcfilter,
			tp,
			LOCATION_SZONE,
			0,
			1,
			nil
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then
			return false
		end

		return Duel.IsExistingMatchingCard(
			s.mcfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
		or Duel.IsExistingMatchingCard(
			s.mcfilter,
			tp,
			LOCATION_SZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.mcfilter,
		tp,
		LOCATION_HAND+LOCATION_SZONE,
		0,
		1,
		1,
		nil
	)

	e:SetLabelObject(g:GetFirst())
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()

	if not tc then return end
	if not tc:IsRelateToEffect(e) then return end

	if Duel.Remove(
		tc,
		POS_FACEUP,
		REASON_COST
	)==0 then
		return
	end

	Duel.SpecialSummon(
		c,
		SUMMON_TYPE_SPECIAL,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end


---------------------------------------------------
-- GY replacement
---------------------------------------------------

function s.rmtg(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()

	if not tc then
		return false
	end

	return tc:IsControler(1-tp)
end


---------------------------------------------------
-- ATK
---------------------------------------------------

function s.atkval(e,c)
	return Duel.GetFieldGroupCount(
		e:GetHandlerPlayer(),
		LOCATION_REMOVED,
		LOCATION_REMOVED
	)*200
end


---------------------------------------------------
-- End Phase effect
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsFaceup()
		and Duel.IsTurnPlayer(tp)
end

function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetFieldGroupCount(
		tp,
		LOCATION_GRAVE,
		0
	)

	if chk==0 then
		return ct>0
			and Duel.GetFieldGroupCount(
				1-tp,
				LOCATION_DECK,
				0
			)>0
	end

	local maxct=math.min(
		ct,
		Duel.GetFieldGroupCount(
			1-tp,
			LOCATION_DECK,
			0
		)
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		maxct,
		1-tp,
		LOCATION_DECK
	)

	e:SetLabel(maxct)
end

function s.epop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()

	if ct<=0 then return end

	Duel.DisableShuffleCheck()

	local g=Duel.GetDecktopGroup(
		1-tp,
		ct
	)

	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end


---------------------------------------------------
-- Leave field
---------------------------------------------------

function s.lvcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end


---------------------------------------------------
-- DARK Masked HERO
---------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xA008)
		and c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_SPECIAL,
			tp,
			true,
			true
		)
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	Duel.SetTargetCard(g)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		0,
		0
	)
end

function s.mcsetfilter(c)
	return c:IsCode(21143940)
		and c:IsSSetable()
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and Duel.SpecialSummon(
			tc,
			SUMMON_TYPE_SPECIAL,
			tp,
			tp,
			true,
			true,
			POS_FACEUP
		)>0
	then
		local g=Duel.GetMatchingGroup(
			s.mcsetfilter,
			tp,
			LOCATION_GRAVE+LOCATION_REMOVED,
			0,
			nil
		)

		if #g>0 then
			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_TOFIELD
			)

			local mc=g:Select(tp,1,1,nil):GetFirst()

			if mc then
				Duel.SSet(tp,mc)
			end
		end
	end
end