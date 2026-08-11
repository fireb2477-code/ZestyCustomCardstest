--Masked HERO Death Law
local s,id=GetID()

s.listed_names={21143940}
s.listed_series={0x8,0xA008}

function s.initial_effect(c)
	---------------------------------------------------
	-- Special Summon procedure
	-- Banish 1 "Mask Change" from your hand
	-- or face-down field
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
	-- You can only control 1 "Masked HERO Death Law"
	---------------------------------------------------
	c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsCode,id),LOCATION_MZONE)

	---------------------------------------------------
	-- Cards sent to opponent's GY are banished instead
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,LOCATION_ONFIELD)
	e1:SetValue(LOCATION_REMOVED)
	e1:SetTarget(s.rmtg)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Gain 200 ATK for each banished card
	-- from either player's banished zone
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Once while face-up:
	-- During the End Phase, banish cards from the
	-- top of your opponent's Deck equal to the
	-- number of cards in your GY
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.epcon)
	e3:SetTarget(s.eptg)
	e3:SetOperation(s.epop)
	c:RegisterEffect(e3)

	---------------------------------------------------
	-- If this card leaves the field:
	-- Special Summon 1 DARK "Masked HERO"
	-- from your Extra Deck, ignoring its
	-- Summoning conditions.
	-- Then Set 1 "Mask Change" from your GY
	-- or banishment.
	---------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOFIELD)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.lvcon)
	e4:SetTarget(s.lvtg)
	e4:SetOperation(s.lvop)
	c:RegisterEffect(e4)
end


---------------------------------------------------
-- Special Summon procedure
---------------------------------------------------

function s.mcfilter(c)
	return c:IsCode(21143940)
		and c:IsAbleToRemove()
end

function s.spcon(e,c)
	if c==nil then
		return true
	end

	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	local tp=e:GetHandlerPlayer()

	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then
		return false
	end

	return Duel.IsExistingMatchingCard(
		s.mcfilter,
		tp,
		LOCATION_HAND+LOCATION_SZONE,
		0,
		1,
		nil
	)
end


function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil)>0
			and Duel.IsExistingMatchingCard(
				s.mcfilter,
				tp,
				LOCATION_HAND+LOCATION_SZONE,
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

	if #g>0 then
		e:SetLabelObject(g:GetFirst())
	end
end


function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()

	if not tc then
		return
	end

	if not tc:IsRelateToEffect(e) then
		return
	end

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
-- Opponent's cards sent to GY -> banished
---------------------------------------------------

function s.rmtg(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		function(c,tp)
			return c:IsControler(1-tp)
		end,
		1,
		nil,
		tp
	)
end


---------------------------------------------------
-- ATK
---------------------------------------------------

function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()

	return (
		Duel.GetFieldGroupCount(
			tp,
			LOCATION_REMOVED,
			0
		)
		+
		Duel.GetFieldGroupCount(
			tp,
			0,
			LOCATION_REMOVED
		)
	)*200
end


---------------------------------------------------
-- End Phase
---------------------------------------------------

function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsFaceup()
		and Duel.IsTurnPlayer(tp)
end


function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local gyct=Duel.GetFieldGroupCount(
		tp,
		LOCATION_GRAVE,
		0
	)

	local deckct=Duel.GetFieldGroupCount(
		1-tp,
		LOCATION_DECK,
		0
	)

	local ct=math.min(gyct,deckct)

	if chk==0 then
		return ct>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		ct,
		1-tp,
		LOCATION_DECK
	)

	e:SetLabel(ct)
end


function s.epop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()

	if not ct or ct<=0 then
		return
	end

	if Duel.GetFieldGroupCount(
		1-tp,
		LOCATION_DECK,
		0
	)<=0 then
		return
	end

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
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_MZONE)
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


---------------------------------------------------
-- Mask Change to Set
---------------------------------------------------

function s.mcsetfilter(c)
	return c:IsCode(21143940)
		and c:IsSSetable()
end


function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	if Duel.SpecialSummon(
		tc,
		SUMMON_TYPE_SPECIAL,
		tp,
		tp,
		true,
		true,
		POS_FACEUP
	)<=0 then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.mcsetfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TOFIELD
	)

	local mc=g:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if mc then
		Duel.SSet(
			tp,
			mc
		)
	end
end