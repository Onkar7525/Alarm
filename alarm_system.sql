PGDMP      :                |            alarm_system    16.3    16.3 5    "           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            #           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            $           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            %           1262    16398    alarm_system    DATABASE     �   CREATE DATABASE alarm_system WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE alarm_system;
                postgres    false            �            1255    16399 D   add_alarm(text, text, numeric, numeric, integer[], integer, integer)    FUNCTION     �  CREATE FUNCTION public.add_alarm(p_name text, p_description text, p_value numeric, p_threshold_value numeric, p_notification_list integer[], p_alarm_type_id integer, p_machine_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_status BOOLEAN;
    v_last_id INTEGER; -- Variable to store the ID of the last inserted row
BEGIN
    -- Determine the status
    v_status := CASE WHEN p_value <= p_threshold_value THEN true ELSE false END;

    -- Insert into alarms and retrieve the ID of the inserted row
    INSERT INTO alarms (
        name, 
        description, 
        value, 
        threshold_value, 
        status, 
        notification_list, 
        alarm_type_id, 
        machine_id
    )
    VALUES (
        p_name,
        p_description,
        p_value,
        p_threshold_value,
        v_status,
        p_notification_list,
        p_alarm_type_id,
        p_machine_id
    )
    RETURNING id INTO v_last_id; -- Store the ID of the last inserted row

    -- Insert into alarm_history if status is true
    IF v_status THEN
        INSERT INTO alarm_history (alarm_id)
        VALUES (v_last_id); -- Use the retrieved ID
    END IF;

END;
$$;
 �   DROP FUNCTION public.add_alarm(p_name text, p_description text, p_value numeric, p_threshold_value numeric, p_notification_list integer[], p_alarm_type_id integer, p_machine_id integer);
       public          postgres    false            �            1255    16400    get_active_alarms()    FUNCTION     �  CREATE FUNCTION public.get_active_alarms() RETURNS TABLE(id integer, alarm_name text, machine_name text, created_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
		M.id AS id,
        A.name::TEXT AS alarm_name, 
        M.name::TEXT AS machine_name, 
        A.created_at
    FROM 
        alarms A 
        JOIN machines M ON A.machine_id = M.id 
    WHERE 
        A.status = true;
END;
$$;
 *   DROP FUNCTION public.get_active_alarms();
       public          postgres    false            �            1255    16401    get_alarm_by_alarmid(integer)    FUNCTION     �  CREATE FUNCTION public.get_alarm_by_alarmid(p_id integer) RETURNS TABLE(id integer, machine_id integer, name text, description text, value numeric, threshold_value numeric, alarm_type_id integer, status boolean, user_names text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        A.id, 
		A.machine_id,
        A.name::text, 
        A.description::text, 
        A.value::numeric, 
        A.threshold_value::numeric, 
        A.alarm_type_id, 
        A.status,
        array_agg(U.full_name::text) AS user_names
    FROM 
        alarms AS A, 
        unnest(A.notification_list) AS user_id 
        JOIN users U ON U.id = user_id
    WHERE 
        A.id = p_id
    GROUP BY
        A.id;
END;
$$;
 9   DROP FUNCTION public.get_alarm_by_alarmid(p_id integer);
       public          postgres    false            �            1255    16484    get_alarm_counts()    FUNCTION     �  CREATE FUNCTION public.get_alarm_counts() RETURNS TABLE(alarm_name character varying, count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        T.name AS name,
        CAST(COUNT(*) AS INTEGER) AS count
    FROM 
        alarms A 
    JOIN 
        alarm_types T ON T.id = A.alarm_type_id 
    JOIN 
        alarm_history H ON H.alarm_id = A.id 
    GROUP BY 
        T.name;
END;
$$;
 )   DROP FUNCTION public.get_alarm_counts();
       public          postgres    false            �            1255    16492    get_alarm_history()    FUNCTION     [  CREATE FUNCTION public.get_alarm_history() RETURNS TABLE(id integer, alarm_id integer, alarm_name character varying, description character varying, machine_name character varying, created_at time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        H.id,
        H.alarm_id,
        A.name AS alarm_name,
        A.description,
        M.name AS machine_name,
        H.created_at
    FROM 
        alarm_history H
    JOIN 
        alarms A ON H.alarm_id = A.id 
    JOIN 
        machines M ON A.machine_id = M.id 
    WHERE 
        H.is_deleted = 0;
END;
$$;
 *   DROP FUNCTION public.get_alarm_history();
       public          postgres    false            �            1255    16490 $   get_alarm_log_history_by_id(integer)    FUNCTION     )  CREATE FUNCTION public.get_alarm_log_history_by_id(machine_id_param integer) RETURNS TABLE(machine_name character varying, alarm_name character varying, created_at time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        M.name AS machine_name,
        A.name AS alarm_name,
        H.created_at::TIME
    FROM 
        alarm_history H
    JOIN
        alarms A
    ON
        H.alarm_id = A.id
    JOIN 
        machines M
    ON
        M.id = A.machine_id
    WHERE 
        M.id = machine_id_param;
END;
$$;
 L   DROP FUNCTION public.get_alarm_log_history_by_id(machine_id_param integer);
       public          postgres    false            �            1255    16403    get_alarms_by_id(integer)    FUNCTION     �  CREATE FUNCTION public.get_alarms_by_id(p_machine_id integer) RETURNS TABLE(id integer, machine_id integer, name text, description text, value numeric, threshold_value numeric, alarm_type_id integer, status boolean, user_names text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        A.id, 
		A.machine_id,
        A.name::text, 
        A.description::text, 
        A.value::numeric, 
        A.threshold_value::numeric, 
        A.alarm_type_id, 
        A.status,
        array_agg(U.full_name::text) AS user_names
    FROM 
        alarms AS A, 
        unnest(A.notification_list) AS user_id 
        JOIN users U ON U.id = user_id
    WHERE 
        A.machine_id = p_machine_id
    GROUP BY
        A.id;
END;
$$;
 =   DROP FUNCTION public.get_alarms_by_id(p_machine_id integer);
       public          postgres    false            �            1255    16404    get_last_alarm()    FUNCTION     �  CREATE FUNCTION public.get_last_alarm() RETURNS TABLE(id integer, machine_id integer, name text, description text, value numeric, threshold_value numeric, alarm_type_id integer, status boolean, user_names text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        A.id, 
        A.machine_id,
        A.name::text, 
        A.description::text, 
        A.value::numeric, 
        A.threshold_value::numeric, 
        A.alarm_type_id, 
        A.status,
        array_agg(U.full_name::text) AS user_names
    FROM 
        alarms AS A, 
        unnest(A.notification_list) AS user_id 
    JOIN users U ON U.id = user_id
    GROUP BY
        A.id
    ORDER BY A.id DESC
    LIMIT 1;
END;
$$;
 '   DROP FUNCTION public.get_last_alarm();
       public          postgres    false            �            1255    16488     get_machine_alarm_count(integer)    FUNCTION     7  CREATE FUNCTION public.get_machine_alarm_count(machine_id_param integer) RETURNS TABLE(alarm_type_name character varying, alarm_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        T.name AS alarm_type_name, 
        CAST(COUNT(*) AS INTEGER) AS alarm_count
    FROM 
        machines M 
    JOIN 
        alarms A 
    ON 
        A.machine_id = M.id 
    JOIN 
        alarm_types T
    ON
        T.id = A.alarm_type_id
    WHERE 
        M.id = machine_id_param
    GROUP BY 
        A.alarm_type_id, 
        T.name;
END;
$$;
 H   DROP FUNCTION public.get_machine_alarm_count(machine_id_param integer);
       public          postgres    false            �            1255    16405 a   update_alarm(integer, character varying, character varying, numeric, numeric, integer, integer[])    FUNCTION     ;  CREATE FUNCTION public.update_alarm(p_id integer, p_name character varying, p_description character varying, p_value numeric, p_threshold_value numeric, p_alarm_type_id integer, p_notification_list integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_status BOOLEAN;
    v_last_id INTEGER; -- Variable to store the ID of the last inserted row
BEGIN
	 -- Determine the status
    v_status := CASE WHEN p_value <= p_threshold_value THEN true ELSE false END;

    UPDATE alarms
    SET
        name = p_name,
        description = p_description,
        value = p_value,
        threshold_value = p_threshold_value,
        alarm_type_id = p_alarm_type_id,
        status = CASE WHEN p_value <= p_threshold_value THEN true ELSE false END,
        notification_list = p_notification_list
    WHERE id = p_id

	RETURNING id INTO v_last_id; -- Store the ID of the last inserted row

    -- Insert into alarm_history if status is true
    IF v_status THEN
        INSERT INTO alarm_history (alarm_id)
        VALUES (v_last_id); -- Use the retrieved ID
    END IF;
END;
$$;
 �   DROP FUNCTION public.update_alarm(p_id integer, p_name character varying, p_description character varying, p_value numeric, p_threshold_value numeric, p_alarm_type_id integer, p_notification_list integer[]);
       public          postgres    false            �            1259    16406    alarm_history    TABLE     �   CREATE TABLE public.alarm_history (
    id integer NOT NULL,
    alarm_id integer,
    created_at time without time zone DEFAULT CURRENT_TIMESTAMP,
    is_deleted bigint DEFAULT 0
);
 !   DROP TABLE public.alarm_history;
       public         heap    postgres    false            �            1259    16411    alarm_history_id_seq    SEQUENCE     �   CREATE SEQUENCE public.alarm_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.alarm_history_id_seq;
       public          postgres    false    215            &           0    0    alarm_history_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.alarm_history_id_seq OWNED BY public.alarm_history.id;
          public          postgres    false    216            �            1259    16412    alarm_types    TABLE     �   CREATE TABLE public.alarm_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(100),
    value integer
);
    DROP TABLE public.alarm_types;
       public         heap    postgres    false            �            1259    16415    alarm_types_id_seq    SEQUENCE     �   CREATE SEQUENCE public.alarm_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.alarm_types_id_seq;
       public          postgres    false    217            '           0    0    alarm_types_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.alarm_types_id_seq OWNED BY public.alarm_types.id;
          public          postgres    false    218            �            1259    16416    alarms    TABLE     f  CREATE TABLE public.alarms (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(50),
    value integer,
    status boolean,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    notification_list integer[],
    machine_id integer,
    alarm_type_id integer,
    threshold_value integer
);
    DROP TABLE public.alarms;
       public         heap    postgres    false            �            1259    16422    alarms_id_seq    SEQUENCE     �   CREATE SEQUENCE public.alarms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.alarms_id_seq;
       public          postgres    false    219            (           0    0    alarms_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.alarms_id_seq OWNED BY public.alarms.id;
          public          postgres    false    220            �            1259    16423    machines    TABLE     �   CREATE TABLE public.machines (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(500),
    alarm_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    image text
);
    DROP TABLE public.machines;
       public         heap    postgres    false            �            1259    16429    machines_id_seq    SEQUENCE     �   CREATE SEQUENCE public.machines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.machines_id_seq;
       public          postgres    false    221            )           0    0    machines_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.machines_id_seq OWNED BY public.machines.id;
          public          postgres    false    222            �            1259    16430    users    TABLE     �  CREATE TABLE public.users (
    id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50),
    email character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status boolean,
    full_name character varying(510) GENERATED ALWAYS AS ((((first_name)::text || ' '::text) || (last_name)::text)) STORED
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    16437    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public          postgres    false    223            *           0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public          postgres    false    224            n           2604    16438    alarm_history id    DEFAULT     t   ALTER TABLE ONLY public.alarm_history ALTER COLUMN id SET DEFAULT nextval('public.alarm_history_id_seq'::regclass);
 ?   ALTER TABLE public.alarm_history ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    216    215            q           2604    16439    alarm_types id    DEFAULT     p   ALTER TABLE ONLY public.alarm_types ALTER COLUMN id SET DEFAULT nextval('public.alarm_types_id_seq'::regclass);
 =   ALTER TABLE public.alarm_types ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217            r           2604    16440 	   alarms id    DEFAULT     f   ALTER TABLE ONLY public.alarms ALTER COLUMN id SET DEFAULT nextval('public.alarms_id_seq'::regclass);
 8   ALTER TABLE public.alarms ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    219            t           2604    16441    machines id    DEFAULT     j   ALTER TABLE ONLY public.machines ALTER COLUMN id SET DEFAULT nextval('public.machines_id_seq'::regclass);
 :   ALTER TABLE public.machines ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    222    221            v           2604    16442    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    223                      0    16406    alarm_history 
   TABLE DATA           M   COPY public.alarm_history (id, alarm_id, created_at, is_deleted) FROM stdin;
    public          postgres    false    215   7V                 0    16412    alarm_types 
   TABLE DATA           C   COPY public.alarm_types (id, name, description, value) FROM stdin;
    public          postgres    false    217   �W                 0    16416    alarms 
   TABLE DATA           �   COPY public.alarms (id, name, description, value, status, created_at, notification_list, machine_id, alarm_type_id, threshold_value) FROM stdin;
    public          postgres    false    219    X                 0    16423    machines 
   TABLE DATA           V   COPY public.machines (id, name, description, alarm_id, created_at, image) FROM stdin;
    public          postgres    false    221   :Z                 0    16430    users 
   TABLE DATA           U   COPY public.users (id, first_name, last_name, email, created_at, status) FROM stdin;
    public          postgres    false    223   �J      +           0    0    alarm_history_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.alarm_history_id_seq', 32, true);
          public          postgres    false    216            ,           0    0    alarm_types_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.alarm_types_id_seq', 4, true);
          public          postgres    false    218            -           0    0    alarms_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.alarms_id_seq', 36, true);
          public          postgres    false    220            .           0    0    machines_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.machines_id_seq', 10, true);
          public          postgres    false    222            /           0    0    users_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.users_id_seq', 9, true);
          public          postgres    false    224            z           2606    16452     alarm_history alarm_history_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.alarm_history
    ADD CONSTRAINT alarm_history_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.alarm_history DROP CONSTRAINT alarm_history_pkey;
       public            postgres    false    215            |           2606    16454    alarm_types alarm_types_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.alarm_types
    ADD CONSTRAINT alarm_types_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.alarm_types DROP CONSTRAINT alarm_types_pkey;
       public            postgres    false    217            ~           2606    16456    alarms alarms_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT alarms_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.alarms DROP CONSTRAINT alarms_pkey;
       public            postgres    false    219            �           2606    16458    machines machines_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.machines DROP CONSTRAINT machines_pkey;
       public            postgres    false    221            �           2606    16460    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    223            �           2606    16461 )   alarm_history alarm_history_alarm_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.alarm_history
    ADD CONSTRAINT alarm_history_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES public.alarms(id);
 S   ALTER TABLE ONLY public.alarm_history DROP CONSTRAINT alarm_history_alarm_id_fkey;
       public          postgres    false    215    219    4734            �           2606    16466    alarm_types alarm_type_id    FK CONSTRAINT     y   ALTER TABLE ONLY public.alarm_types
    ADD CONSTRAINT alarm_type_id FOREIGN KEY (id) REFERENCES public.alarm_types(id);
 C   ALTER TABLE ONLY public.alarm_types DROP CONSTRAINT alarm_type_id;
       public          postgres    false    217    217    4732            �           2606    16471    alarms fk_machine    FK CONSTRAINT     v   ALTER TABLE ONLY public.alarms
    ADD CONSTRAINT fk_machine FOREIGN KEY (machine_id) REFERENCES public.machines(id);
 ;   ALTER TABLE ONLY public.alarms DROP CONSTRAINT fk_machine;
       public          postgres    false    219    221    4736            �           2606    16476    machines machines_alarm_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES public.alarms(id) ON UPDATE CASCADE ON DELETE CASCADE;
 I   ALTER TABLE ONLY public.machines DROP CONSTRAINT machines_alarm_id_fkey;
       public          postgres    false    4734    221    219               D  x�E��u1г\�Z�y7�~k�02tI��d��_�9�G7)�J��B� �����N�a�H������0i�%{��Ѥ4��¯��$+ߙ�r]�a'	����c�%�	#�O^��L	�4b�y��I�;^����0���g��3��P{<���A�2�m<W]��*"n7�h�g�aS�)�r��i|�@��	�3�{FUЛ����͉S��9����Jp�1��Vԛ��q����7d��3~�O5�'�~���$�u��;��cJ�
��ݗ�8���U��<a�n9O_���v���u��̝'�}>�_Aux         e   x�3��wuUp�I,���
�y)�ɉ%��
@N#S.#Nǲ�̜Ĥ̜̒Jj���4s����&�%��Ѓ�"(� ����Մ3�4�U0Y$-1z\\\ ��C         *  x���KO�@���_��2��y	He�vߍi^	m������$�;۲?�s�C�n�����}��Z_�/��-�!�!����yV�!�zt��^��ɟ�r՟]�.���NV�f�������>�{ƌ��{B���]p�BG쾜�V�pe 6@Р�3�6� Q�B�	�t_rHMH��d �	sU�L	iG�u���E  OD�i("$��6	�tH=FM�.S�:L��b���Y�7?�����l�6H4��$�Hq�,-��}�'q{w4�0:nI�
�'9Q%���1|��+�Ǳ`�*Y�ɰv���dQdq�$P0�A�����ڳa��s%`�, 3�<�����ߏ>1�1�P�Z`�%D�T[�.�����z���u�Iа�@v��I'���h��}[�0դ/�d:�̲��S�7�Qy����[;�� *[�������ò� �[,
>pf��MW[���cd��͝��w�X��]\]�^��p��	��t0H���v��eR��5F�'��ڌ�����m�@[���-�F��i������FZg            x���ǒ�J�&8��gUhq{��Zc=Ak�x�b���RV���iF�㸯�	r%�Oj���?iIV7c��>M�_{���Ӟ���W��9���Y��4����WW��g�5k9��_�dm�c�kz�H�f���#��J���cߛ��Omɘ�������M��ݚ�fx��ￎ���jƿ�bO�?�|��}�9M�����?�?�?A ��g �� ��3
�3 �Cp��<ٓ~;��o;���&[�!��K�_��,��e��hʢ�ֻ��/t2Eu}i.W{WK_{!u�@W�`O�@wM%_O�@��t�P������e�[�9��xV�����f��jR�
0���������Ux��?�l��&�o�ٶ=��`}����?��/EќD�-R-U�Y�Y�������ǩ��������������=��ޣeI����������Z��,G�<A�8Wje;
�F�z������̹ǂ�����'���fmח�f����r=�ÿl��P��jm��{p�ۮ8�:9�:�?˒l�j˲.���(�-O^jڑ��PEi�uU�y~�K0;�x��
���4��ْ8#�{��cf���z%0
V��bzţf���W��Q�QM,��� E�Ɋ�>�餧D���t��� �Dzϟ�E
�Cv�ԕ����Z&&H�N�/����ș�K�,�e�j�`}��;DK�"7L���'z�5�8�C�8�.�Է�eXNNi��1C�e{P� 
i����	��R'�UU�H�i��C���:��2��L��:�<9~�`3��v�1�� �zנN��g��.�j$���{1�g�j��q���˂�#dP�
=(O�b7�BZ�CyS�A����J��`b��'�+�X�;�T�ϖ�A3�<p��{WHK��Ӻ�.��̣�q1J5�v<�Y"���R!���ܛ�T���A�����ڶ�����}���o�W��c�&�
�,Π�f��Wh�︲�[��][�l!T����c-ƁQ����,�%�,�&��o���V�ج |�o���4;;�E�uDS���j��:������<L��?�(��o���ْ�ف�#\qY�a�R�a1����7UIg�+^�7�3��
ks&U�eJH\���Џ����f�-���*�|BT�����d]n�5/�8�(�IF�_���`�m�_�;��$.n�g�KX%�I҃s� ��e��4N�!����3\�Q����M\�V���˪���	[���������O��`�{"�6��m�8�=~����Y�4�� �ͬ��c[��(�}y$a�c
k��IG�ɞ��V�C�,K�Y|�M�׮Nl�IH,@k��ª<�������o_� �����ŭ(a
SY�1�s�����@��L{�8�wj^��/�0V�KOw}*Y�����>һ��5a%pw=�� �N�k/f��䦧͡Y%YM�C�Ȑ��L�B}s���~�lYubfA�R���URs�KZ�`���6L��cN�V���띋팼�Ե�Ӓ��dYdCc��T�B���Kf�3'���TX�h�+����ڶ ��Ť1���X�. ^�B�{����7$�n$��SM��S�?{�H��0qx���;8%Tf�f���9Z�4�4f���$����o;�����A�P�-�ݎ"�]��p(a��C[4�4S�.���:P��T��;O��C��>���/�/�cLb�~O����,Ƥbc^��H�����P�ֺ�ێ�wUa��@b�0)�[��q٘�ΈAp�����X�#�8�d�!]��M@L�IA0 E�}�{�ˈ�vJ�!�x��x�(�N������cH�|�(�>=��'�5���ͽY�\����A)�]���|w1��u���t{��Q\�P)Llj+��ھn�6y�Z�a�_c�>@]8!I�Y��
K��:�c{��������D��"i�G+������.�p%l��D�d���Y%�� �?��x��Έ�o|1�2��\�p�^M��,v�W�n�О��@@@X�ӑ�8�[�$�nS��,��m��\����:��5A��"���.C���M%�4�9L@�}��?�'_#�P�N ���,n�LQC��{�^�ŀH�_�$8_#ǜT��¯�M�dN���S�ȋ[���/[������+�h����-j�������yT��|E?�T|v'�RO��|1I] ��E��F��}��c����^g���>�Ԁ_iά\���]�f�H��7�#�/�J��ҡi��Տ���zϭ0s�����~�;/:��ϯ��C�o�Ͳ��(*������\t��JiҼ�W����7�V�؆�͕7?���@�y�=o�]��#�����XU��z�9#��B�T. l���O��(��h,�A���!,�%�;�#��>(��Ό��7:���F@^0�À0��J�2�L>Ӧk��HaO��/G3��"Oyu�������QO���jwv�c�5"iϗ�$Q�א��|˸/!%$P"���� ԘuخfO��Hi��\9"#���R$DyQ"Ґ֗U,�4�倕R2��Y�|I<���P_w��D�v^�dRһV��Ή�f<⎱ږp=��v�A�,��gn���;\�h��o��I�_b����A���4y���D���Z�B��/)��	�\�ªhA{��?ā-#���eH�OPy@�:�堻>����/|��GO��쑎�Y�W�y�>��������6ۦy1�������]Т������YI��ŢԮOj1ȱ0��b�Ƨ[��8�L3�s��Ӻ��Ow���;+9�u ���sL���-OH�j�%��o��\�o�G>\�W�Ƚ,o��E�=,�c�O{�ӝ�������hC�L>N�>x�<���P:�q�,13K2%�-����sx�k�qxH6��]m�\�}_��%�c�Ιs�ٯlDA�����$vUr��ý�'�o�[�U%4)8��`����
~�D��;���p��%y�AGzRxU�q�V���Z5�:�qkw.Ӎ�Tvȓ->�1Ŏ�A.7��6��aT���YP�pGUbiqp�Rl5`l.z,m�u&p�43��\�j���oʧ���	ƾ$�h�u��N~8�(D(�vL������<<!�&�O�D�����}�m\yȐ�[�g�#�ԫ��gf�@r��J{���8.t��m��eV�(*j3�A!�iU��HC�;�9T��DZ��@ೌ�s_��4�kPO�3:�������*���8�.���vC�­�O	4�$\���C�5��r��*9?�<EA�΀�wY�_J͵��x���i�E��:���X�2��w���;o�(U�/?�A���(t�W�嫸~q���>�XZm�<�tő|G��2x�^Z��[2r�\���S!�	�e����`"p��Q٤����ߓ��"��D�:Q��v.��6���M���d�ŭwQ��yI��a�8�~C�1����d�p!���ҕ���I8����W�������_	�'Ua��r�w������:ee�[�4��O���c)3�om_�x��:�H���+���`�~; 	nfY��o(5�@�6�&����h���u��Y�O֐�}��1 7��ynA-����2����6�G��3���gy}��bor�\{W���eC�*�gt]f�$���lH<s�NvtooE��S�#��_��O>�vx��R� �T^%A9��~���tV��-.w]�0�aa���M���;�v'���j|B]N��L�_�b�?�7���f���Yi����i�ՠQ��8y�z�����!�Ό�XN�<j��
^;T��<�O5�q"���8�*]�[]��>���@Q+z-���pY�bͰ���M��~��}S�uV�M�|x�u>Y�U˲��� �Q�Րp���h#��L�WX~�k�tS����u�:�Vs!�,*fY��A��6?a� } �h��1���A_v�2;W�R۠�U�zmz�?Z�{I��i�&�a#X(z��5u��e�7T�_k��M�k�u�;�&��� _���+�&��#����R�;#�����l�l`�    �7���T��g}'�����
VS?ĶK.�
���ڛe�A�O�k�1�E�qQ/;��BM�7;�O��/و��xಌ����������aE�l7^�X�F�Z��������"u�\�ڪ�7��+ͷ"�}?}ȭ�Q�:��Ca��
�Yq���M�6(��g��+������#jAf'���j��\\	�* �^��P���S�	MQh�䤘�Q���»�ޏ#����'П�I��{Xr�'7>7����*�&&	����Yȶ��&hᢣ>/�~�Ih�Q�ԓ�I��̝�Pܷ�k"��VW�_n���!���9�NHT�����T�����c���g�ݻ�\������({������`G�C������ʿ�b��Ԯ�f���r
�iz��ѳ�KE�:�i���/`�����7�S^;`��r!�HI���8m �&�(�K�J�'/�E4�����JR�q�{�Z*!B4��:q��b�<�P5v��A�fR��Zu3�sa����PY�ZN�s��5]�+P�:�"�w���d���ob�m�Z�!fK���XV�l�����[�/���)�7�,@��+]��S��d��~T��VQ���J10��:�Y,�����2�z����!�����ưa�bu	���ސ�7Wmb
hi��j��l� �y���xB���kݒQعx������j�=;��"�/�*׵��ՙ;R*��ˮh�vpW���_�-%72è��^r����	9/��E\aqe�Lo�qy�"�S�;�.�K��_(y,�>�Fҗ�ܑ8��5�	���" e��3Q`�؉ et�yͬx���
Q��0�[B��W���% ���`'%��y�jc&����o��ׁ�r�<j'�V���t���T��'��Ixx6b�J�_��z�!b�xr���:e��3�c��SLJk���i�"�u/x�:FUx=�o>8٨�|gX��{ �|_sLڌ�=���k���LSp��D��8)�^�p��~<��M���2����1�ا�׼0���,��J���T&�w^�P�k>�b�ry�T��B�p��!�%{<9�Xk�kcG��i7:x��c��{�Z�
H͛/��g�x�.���:�U"��/����+��/>�����}���o�r� X*Sy��&G堐�|ռ��$����M���1��*��\z�H�܁�Da��ȕM�\n��n٠����Z�u|�N��q���K��
��m���
'@��Nwi5k1?�\�^�%���e�~�W�x>N��@�-2�B�.39=��(�:�݊A">�i]k���=Ƨ���\��*y�o8`�3�gk��7��{e���o�;�ط9�LZqe�:(j��/.�O˧�iK{�v�����40ñ����
�҃����(z�32T�\>��+��������o
-p��v�^͙l�X)B$�Pm�G=q�`T>J��]�W�B|�(�c�i�f<nwu]�-�;�dP���o�lѣ /º���k����?�2tȇ��B_�E�N������C�$����P��߼��F?O�Q�Fgxi�Mi�W��5>���O�~ ����~wԐ�|� ��E��L��]s*u��j���ڬ�/���>���ߙ�ă|@q�pyO���ꁛ	���%���<�1��`��Bڢa�m�`3�M4� ���6^�Ή?z���KS��y�
@P_�U�w��(~��?bkZ}���+�_�d� �D��̾��o��������
P��*�>.?��nTr�ڎ���߅�Ϭ�'򻇿�P�,~��N�^�QH*�`4�'�����8��!�#��r�>�68�|��/�H!�4��sw3I~� ڠC-� �CGr��k�����{�L1]"M�n�]d~%;��y�Ǽ�cҸeǔF2������$�>UVv`L��B�W+��"G�C����xL}���
�H�!�2FBF>�r e��3�q6�N���21,#ċ%T7��l�-=_.Ë��ڏZHm^�,�q�?�Ns���q���wp��9�59�܊)6{�U~�x1���i���D@��p׵���V�y��'ֱ}Q'���{��R��\��z�`~~!��T@�Һ-�CH㾵��0t%/���p���}=4�_j]IHܒY��x�dB:��Bڍ�;i�_�d6.�6���"�5��3	-�p�hT,N�*�c,Rp�#߽��������*�������SZ�6TJ���c��}�O���״\ɮ�Tt$�u=���h5`�a�敱�ǳ�qFx�-��M��!����F�cD��c�F�JZQ*����[�Z�R��鬊�v��Zx�Ir�}�g���_�����"��Z�j���C��i��zd�ȪK�b/o�
�xJ�h� �P}{�=7p;[2����q������@��ed�W�i����q���[�ϛ�v.���229:7Uls�LшNS�I�i�����2�-���;[��Tj���oli��l۶uTAF-J }i��#�<�pV�}��M�&�X�T�L���Š1/K�A'(a%S ^�����A=N�	�>z]�L4�'O��ŤNA�;���V�o�6p��캄Gz=LO��l�	bw���G��:2-����W�iM�W��A9�ɱ�Ћ�X-o�=.�kQa�Iqϧ�M^���>�Yf��R_�{2�twT�{���s����[ه21��I�^�jmt�5��VNPI��)���,2�h_��@\�~z���C/�b�E8�')�b���e�s���D|�h�f6ת1��ި��gtm_�3?���7t�kӪM���D$\�W:�W��������y�k�¯l�W��Ӝ��cm�Y{=�R�i~���"�x���_?�
���5H!I��&���l�=B��t�fks�i��m`��{ż1a�}���o>�}o��h-nl�̅��z�&F��%���]n�u�t�BQ��)���UttDe�Ҹ!������{�Z�!�"!~F������b3��;sl�{�be���J�;mI�$>=��Dg�H�G�\�sA�F���.0�#ze��#�������n����S>h�T��Y�D��h%e˓1�Ly�h���E{+�q\ +yr�+�|瀔+�n�����f 4�ׯs�i�7�S��ɬ��i0]J�q�
tɳ���I��枯cF�!�Ɠ_�65\/uV��f�6x|�5����"	��f��=mx�Z`�w�t��y����YE���i[�I��i�B�}��N���K?�|t_<����r��߼d>��+%��χ�&([���? �5�b���o�J��fJ��������K���_���.濸���`���a��6t�w��.O�s�w�����������E௱^A���2��
�-%��g��K(B�WdvC�T��bI����)���֔�W�4+R=�%�]����)�+������~�
��G��B8��	���Iq��H�W�G��)�N"��T.sk���C��7�<�o�>]`��5��ջv���H���=Ү#���^��Zz9e���a^F������G��4�
We����_��['g#\��-�R�XҊJ�e�a�~��"����w�#-]�D�
G��ݯ�BSb�0��}��5�̜�z9u>�y�:VJ���������'��Mg;6���@ `�P����^���Q����Z�ܱǭ��N���U?��k�Se��V���I��i�o��W���j�azi��.�|k4[\�R��%�)�5(��ɠ��.��:��q/���9Ri �'�ZW��CJˀ]j)���"n]ya+������ˀ������/��;_��o��̵ض��S"zl��W�ogdwߌy��]Z�b���l�?7��rZ����'[��u�����<�=T��!{;�s�)�����/u�K�_w�)���ݪ��Oi��NU	4ҋvJ��a	h���RO������ۿ���mV��P���ǲK��E����yh�:9��2��"��R�?�Q�M��5�Ew���Z�ݥ\�-"��]�I_^��e��3m    ��F+�J?������_�K9�|�a&��ϟRP��,�?���jΡn�� ��"�&h��|�
��������/�2O��M���fZ
q.mD:���?3��N�g�����/�IT�/x��O�D�1�����M?Rd��0p�d�0}��T���Ȫ����G"�Z��L�I��� d�:�n�Oξ�X�n>�#�K�6�L�)��'����JooL润e�}�$��D{L*�~�O_�4�Vuo��]�/f��a<���@u�פ���o ��6�5,�BX���x�uɛ��*k<U��z{@%r#�d-RB쏡����c�1�J�����e̶�ѸSV�?t��	��>V0��.�kvA�xWk�;�nl�&�+��%��wZq�R�	���:�=ì�W�5�+)F�%~e,��&��h5Y��m�y=Kg�L���G���zwG=C+:9E�|�� @{�R�|M�Vʖ9��+2���c���|!U}��]�6�q�6n
� ���zV�Fu�f�.��j�O9LW��2��+��2�Y���L��H�EA�q��yЦ�r��a����=w8���T�y�h��t�d�l��<&��HΛ�>���w�_��+��Z��`�Y���)1��X��NR�k��x�M7����'����R�!uQ�ϯ��8w#z'����+Ŗ����"�D�\�����o���
��Q�xCH�4��a3��(xDE�j�g���Y�f�0X�P�ʢ ������^l��PR���ڠqy�Z5]�b�ݙ
&�ю�/6)��n�{r* ��F]Nq�D��69;�{��;��THZ�����t�4*�&�W����p9�� HMW��gmoDc��֏oO��T\.��qHv�5D�ʂ�;N�F�8���וv�LQ��=�M*��˘���"@:�*�D�q6޳�=�:ɚ�	X�B>a?5+֒�I�{�����:�EjK��Ђ@����:AM�c��(�-�w~O�B���sGɿ"pK^�KvA^#�<���&���*2v��\D�Z8l7E5��7�3� 9Ԙٰ��jc\����\ �	������Y�ʜ"��ю��2�~lѱ$uvBI�JP��o�}��f��k-�_�*Ŵz�:Q.N��S���w�r�>��24V#�bf�᪡�b����]�Eͧ	8�^��f��8ftԵ�%��ibS���ݝ�zrB�7l�8u ��*v��;j J�㊗�� `�$k�����n�$ UN�_B�kߓ�l>��X ����>}NF��*?5P�̥�e�a�0��6�\τ9}c[��n��S.L�d�	L�3���c���u#�[eaH��iSp��8)���+2<О���~�ɸkN���]��W7�Ћ�O��]�D\���dX=������CXV�q�V<3���ŖQ�_s��]-����H�Xָ���e��0�3ć)�J��5%Ĩ���C|w������`ʚ����Ђ�����ś�F����g"k��<�\��Z@���u�.J�o�V�^�P�H��z%a}�ӄ.qbؗ~E�f��f��o�H���TFT p"q��d���l��(�D��#��2�������\{ֹ����4�>����fpSҮ���c7%T�xU�*��ﵤm�=5�>�'ʆ���2_s�6�����XV�
]�]���-n�XrZ��}j��o^��>��krw�>���%>��5O��W��4ۂ��^��P�LU�i�)Yr���1���zq��е�]O��%rjdR�M�Slq�iP j�6g>�7��^��|֚=��eEE3Fl���G�Wǟ�/ճ� ��b�w`��f�O�o7e��������z�]�u�ó����(��i9�����(�&W&�,���KU>��1��r��~E�m�L@uR_ ��ܺ�Y�[݃�R�%u���I�A}"��u���� �u�����Q���悰oO����j�_d���iCQ���AßA�O��������mY���9���6h�s�!�.C�-�� ȁ���|^u���P����L����ڰ��~|9�=�b�z�5TԽ�_��r���7wb4�j�Ɉ��oX�qbg�q��z-���cR���ҏ�����_]����G��I���s��)Cq�#�35�kj�oti����r̥���S��J�N�)6�sپy�������o_��%71q`8��zvd��E+G����A"�m0�x�i�:d����$�#�էH/�1)!�}~g����L��J�S�z��z\�>��P��.$�?�}�f�������0�S��!f,FI�ZZ,\��W�3!���.�����$7�r�ke�b�H�Ii��a<���f�m.��v�L4����������vߎoU�Ĳ"%y'p�����%_�,G���r�]�/T��}�����)0~���i�u�#��Ġ}���:<֔2�W��F(^l��(&�+\z��l1/��.Q�Z�ك!4Ю\���@�1��ܷ¢��߆v�9���l������w~h��s#'���(���y�_c/�D��C���o��r
�ܙ�V4eX��u\���/'л ���������}�r��;�-��W�%��L_��V){bP_����[��#d���f�����=��4v=	�fPB49�B� ������NPb�u�~7��I��شH�f��6	�A�ϑ+ޥ�hx�0�
t4,X�?��4g�?�6�Z���ȱ �/��!Ǝ��ؽK����C������o�^т�S|c�C�0��b���a��0��DVq�x����K<��H��Z�OD�+�z�K/ ��3Y�߾� �掷��'=]��e&�OP�ߝ�Fx*�c4�Cg}��ۍ�o4�5�w��GJ$��Hm���̖[�2Ҟ�+��������å(�2����E�S�	���"�h
�����C-����i�+e~�i�W���F�h���%&P�<.��3�ӧԥ=#�����S���X����I��3�?��п�t��|+�;6���;FV%�{B9s8�݈^l�ac2��i�9��o��{�MK�!z݃θ�7I}c���7��{}*x��(ZAh�?�R;P/k� ��L�XQ�&��}�ӯb�>h�3b;�Io��'H7���I�����Q�3 \e/~��O������!�#�7�H�'~�3}m����BGL�1�*���cG^A@��ϙ��D�N����
���"h`���XKVǟF���1�Z>�ERg�瀕�g7�)�շ'ڞ��D��qs�~�����9x皜�~Y�����S��ǧ��K�>�ӌ���P�����3���m�Z��j� �y0\~J�U������������.F�2�a@��n(n��F�6�'��g���}ӈ��|+�_n�4|yL�:Qe����<�NA0����ǲ�AtE??�H��	��!�`A�M�R�ԩO�3_{:(�k_�]����P�DM����~�Ʈ�v�/)_g�	�rD���Y�MHK�iO2eu��=���۫7�K�i�6~6]�?�:������O��v�y��c�脒4��^Mo��F82��%����z�XU��خAs�n^�u��dQ����A�;ycW��;��ӓ�>�%�i[��Ж��[FI|ˍ�Kk�#�rTU�%��L�;����>��c���Yf�U�����$[�'��P�����$��W�y�&3������G���V��W������|%5<��������y�j�Av\H�����0g5� z
BF6o���%!?�7_Z�Z�>��6�6�[�����׏����\^��/�P4$$)?ٌv8�F8��T��������`&�f��9��k�����W7.9'Z�/�;xۃ]�t��/�����zRF� T���,�Q?���Z�@?f�T�?x��
)��A��	8����B�`E#~��\@��Zml���a�`M(#��ӫq�^���`:c@ˊ�YNT��T���iT�ɡ5б5[N    ۤZ��j��R�eȑ���4���P	b ��鷘�	4���y�憮��'iq��S\�;'f7c`���䎶%w��Ap�F,U����k��N�(�tO�>R(�����.��~��|�꼦:D��4���%���h�O�C�����VL��Ꮊ�V�v*ـ�-�\y��P�@��Ũ�S�9&{��}���g�,-��ԃP�v�V짼� ��]�xT��:Wnd����v=�N��]�C��Z�s9���=+IȒ7��uP�L�Ӈ�N.d��nC�^�鯀���h˞��%�c�,���Ws��<)�W�����T5���9��=�0���_E�&�{Y�AN�JpMΑ�}u鏁�e4���#/H��9�}$��=�‪62�d
�r�'���~ۿX�%�	��� _;��C�Y%�l�/�F�g�(���O�{�Z-Z`���X�jR*ז��M�s��^�	@�d�J�Í�@��՗)��%*Y���	P�^T	�)�!���E�ȝ���P�8d��%ݽ):tq�W�{4C�}Δ�r&#�]������mo�a�S�r��]/-��g�+��ϛ��@8��#A�c�k$��#ۆ�l��f $�Z������N�V�֪�r��2\s<}d���ㆸ��;�f�(���T��  aS;d�f=B��F�{�͈gNt�ko��w���AO]d�³���f�=�
�!�x��b������ֺ:��Y����Y馦>�-N��⚡x4�:~��o�FѲ7��6k��T\���zʒ���s��9M���$Ea��ܡ�}շ��۬P�Kl��r.�qe���+|7%��Ȥ��,��UϙF/��c�ك9�t0,��
*UU���d�@j�_��P8�W��cIB���=W��i�D$j1�֚*�Zs�C=o3ݿac�U%$�?'���'@�֯�6�^��+4ܺ�9�&��+�#�'�����U3
_n�0���Y��;H�I�-l�����v��#keӐ3�8���3��ʚEo�B�z=ql��T�E!8^�7���ZםV��{Y�>���������Dx@��0ϳ;�-=�Z󌁚F� ���x�"����}f��>2ң��=!�F�>���%c�����z^��E�|�� q����]��~��Ά�|�7Y+�}�1�O�?��}�Z�����k��_�iH�c	�O��t��A֑��L����H�����щA��Dk�U�4��n��Pv�fCH��r�ԉ/����dP^!WK��˳���۸ǌw����]�d� ?A�$f�W��Crq�Cq��hb�������O�����# ��5{�w	�G�_�I7b��s!n�8h��}�wn�&���rO^�{��?��D��~���O�s0d����J�v��:5��(ʯ+ö�r3齬��T�
��T�K6�U8�;�G�Y��=X]�)��l+_�d�J60��0刔��2�|��bZA�r�����lMgW���>�%	�"-ŗ�	;d��2\��K�39R��	`�q��/�t��*_��龴`������Ae;��zaih\�4E���5��y���jid%��UiK���!�����o���?�
(��?&��[u�?Ͽ'�t���I�7������%9���ϸ�SlY�O�l�R'���Yo�?U]V�LK��k=��o�������7=�o����3�W���������������+��K��%��<��rL����'��{���|������;�=���\�EY�vC�ͯ/�S����_�?��+%����1��Ϲ����R�Д'ПGq�;KY�P��������Oi��<Gry�8��嫌�j}ޛ�|y.��5��'߼=������B����̿v��������r¿s��*�DSM[��9��b�,˵|��&��w^��$u��ݿ}�l�%(�q�3��c�<�{���L�y�W3�St�S�lH3�(�n�*��nRH�-z����ww�I�W�)&��~\Xxv����Ʈ�lPy$��Y�~�<����\R({c�8�x{��hK�~2%i�$�.֛BL1�YX�ⰸ?�w>���\|�N�y��ȟ� �	<�Eq�O&���7��#�o?TVW��^�~E��v[@�߸ �BU-���b�|�_�9)������&��?�׷2��@F0�q-�6kh��>�۵hs8�7i�p��y1;�uu��7c0GsE�esc��\DQ�1m��_4�!�fn҃��}�V�/� ~.���Aڍ4.�Ǆ�3�W���j��󶥚���wMP�ߏXѓ�.�?���7�haC���G������,;A�(�K��v�:2�z�|g��0�����$$>�����ƾ�E���4"u�R�W=ܡ�C~�:�Ds�K���5,�_(O�S����;�&�Lk.A/�E�ܱD��!�Q���>�_?b�i7�g����0�����I7&����?�ug� "X��B�s2�٪���_�dԤ��Rj�0�W֫$��C�K���y`�M\�k4qcA�\u7�C�_�ҁ���j����7w��c�̸˸0��;B�37k:�����qq>_n�al7�tK2��KYX��-�EGFV�ƍZ��vh
�m�@�M?���D�������%��NJ�v!o��Og�+x����拊$H���S���|(s�R�8�w��!��L���i�I1#��h�v쌊��1�#���"�(F����� ��NYCR+���[�q��ah����)�X!ڔ�]��g���w��g�R�r��2�h%�����2�X�\�χ�_ꋀ�ꇷ ������l��~	U7���fOR����ėNr�|�ڢ�� �q�$����VN��a.�j����m=��˅W�:v,���C�B�d,w�WA���Z�p�b�lk+�eD���o�QĪ!��ťzd"0 ��Q5ԭdq� Du�\��ژ���8糌i��1�V����)s�0L,�a	lLr'�8�~h��l��w�؎*:���M�,#ٟ��X�L�a2Է�.ݷ�:6)2=�ޢ�Hp)���>6�ED�a�&6��	�Z4ٞ�j�UHI�Q-�"�)�tG/Hqϡa���嵍_?oB~g��3����� t����f?~��w�,D���H� �8�o�߀��P,~�:
�[}0J�.f"�ڞ9�"]d�.�A�lQ�m�Ã"�*�I�N��s��o�ꗅ2��~�] a-��(�5!ܘ��/�C��� �E�H4�Q�	��q��@���h�a�����.3�2aB�:�:�)�ζ1�6��s�k���Y2J�'��yߝ�F'��x�t��Y3��E���3�n�c+���9���=�3�]fb���-�A��N {̲��y���b�M��tه�s�,t��<���}C�L����t����efq��I�^ҟG��đ~4��]%���tMoہ�q7���~�?n���
˛�-�a˾hS�k��L��v89�S5
�.u�P[�`=��Ĵx`@��ʬS���,E��KC�|�o��A�{ʉ�U�Am/k�3���eLQ�wZ[Ҩ󾵴�+ޝIT���P����P/yOb��f����S'I+M���'P�ϴ/2-�Ҫ��)&��8GIO;?[�V+��_l��̒�MlU���~�F���I�fZN�~m����j��Dp�1U�HK��rk�0�˙'��G����@L�Cv�/p�4P�pY:����
og8�t�i�qf9h*B��Cz�G��ES����ts�����C9�n��L�ũ7����N�c�!=1�y���ZI7p#]~|(��K�y�C]0�����j�{�]^7knSy�l����'N��	��C]�'�g�����|�,���y{>�9���_��;�ى}OMӜ��Mq��4��J�2V_	��r�F~�V	�p-�d���Ҩ����%p���#���4�l�T�����֙�rϖ�iC�S�֓��t��"��� ��"He�RZ*,_�l����5ݟ!��9ȔWf�HN�-w$�Ů2���Ұ:�rd}�    �_J��jH�#%HwR�Q^�(��A��p�Jx$X�2��k��GK������13��wMd�+�O5_N�|5C�,����}(!&�K,�~*��b�B�w���i&������ؘ�]E�v��܍�Z��	|�"ɼ�� �h,,'X16րf�b�5���&�������l��8�aVVs��-�_m\�R�{no��\���˔:1�Ս�Ǿ��)��i�«ړ#J�q��p%�fci��Jdx�W�4A>!�က�.J������*3���Թ���N�K^=��a4w�[��-�%i�	�2�M];�<%WB��Q��1j�O(���Qk�PX�s�E�@C����h�����ן���U�9�Z�,�i�f�[1I#O��HKسb~�kJ}_­�f��N�N�G@'�^&ӣ�yo P�8��)M��3��^4�� X�|��Ef�f�_?���t
� q/!�)0�2=�20��9+~��[=��+	�E�Zz0>�RК����G��޺��c��#$���S<����jǡs2IІWz3.�:�חd��|t���%q��,����?�rȹkճ��xw֗.�T�����^����Z����S�㮕Q�يH�g��ׯaHjg�]L����R�y��o��<��8����*�����M�0�n�4���`�/���ۼe[�6���0y\����ु��U4�g����d:���t����/���Kh���x�h���L!5�7ݟ�U-آ��Lp%l�g�;X��$�b��*��G����C�G4o
L�Ҝ�m�|0�;-��;��1�r��[�ح��B�X��g����*����F+��]k�Y�/r���Km>y�S3��KķRx�d⑩Η�?�����)�|1�-�Pb��"��қ�_9%�*G�D%r�%���&^`zHnh����o|U(]�h��|��ag��������RYh7,l{����I/@�Tj���k�*�����1F������(���~���:]�7F�$�r �G��2`�;�T6Ǳ�jDä84}v����қ��<�;e���`L	� ��|~�{��[$�T��ο'���a�/F�#�ʇC���B�a���ݺ���v�� `L˛*��_��~NZ�M�H^F��ۢ}�h�5�*kC�N�%���5O�=�u�yIBGzP�Ţ-a5_#�_�y�餻1b�7?��,Մ�7��b(��(�]~�/1`�N?��+�'K�1oQ��X�� ���ֹ?li�R�	�~��Ƴ�?��J�[2:���L0�mj������hx��L|�?�'y�u�*�c��Z��m�]X�W^�}�� /Q|��F�޼X���9�m
��Kʃ:&��nj^dl�����F]�/,g	/�@L
Ըߐ�_MQ�@N��t��}Z���;�0�\��� �����*7�)>� cS�w�S˾��A�?t��_%�EXb�E��g�i�Hm��u��[/z�)����-@W�T����7`!b<�Pc���N�<3�����F1'���&Ν����B�tm���<��n@)n���X�O�h�r&gT;���/��㘜�Am�2���s6�3�����N��G�tNڦ�D6�=���AՌ{���=���� �]9�������E���D\g����~!`b��V��OHS"af�-��LdSaĮ��C2�fk�OD��������A�B����n�R���m��d"��aޟ ��]�lC�f/����w$��Ȯ+"8.��W)�����dS��ՠ��/ǌ*yц�up��s��
8_�٪�,��z�T��"&�y/
���(�ׂ�iZ�7&�����78h�R����.bc��}}��^F>~� 6l<��Ij��h<޾�^��#�	�$��j��Ҕ�M�X�=p]��9C��6ƶp�D���df���?]��/���`މh`kEt�+���@>�ו����Z�Y3�P��Ax���ۯ��C�+k�F�ֈ8O�xh�d<`J��+-�ٗ�;���=	̗jv��#�;Vf(��T��d����@��+��G.��p��s/v2OwFl_V��yf���أ�nA��|�{��범Ao��?�A��7T��[j�:���nN��:�j�#��9M�؝�gB����r`�A�7�>�x��� ���E����M����W�D3��p�c�eȠ]x�\<pl�Ʀ�t��a�R�n�4|�&r쌚�A0gM��'𹶉dp���و������;�n�Qr(Pk����a.���觮ے�x��<��{k�W�wP?G��}C��W##�L�;ctN�Kcr޳렰�Ynx�}��a�[A�G�'x�
2݂9��F5ZU����ή���%y-Hm�9���T�áL1�$�~%�.9z����E2alE��j���۾��aUr�F<hb1��ҥzj�f��O^zӤ��AB�?�qa3��q8><�^��mעI���l7%/0��+e�_���X��p}|{iU#��qܼ¾���*��cA���B���Z��۝�cʲ�'���ES��d�9������,^����2�MScz!h" �I��9[���&�f��3�a�~���6��N�B�B�YO�,�(}dz9����f��jK����$h���+��
����`��� ��	�x�?�3B��&v�M]0�0$b:N���nP�T#�,�jP_���zY��ږʙqr�2��yi����al��XJ���u�l�F��'��'xpI}��)U
�W�\G4�d�8k���*�E��qlx1W�q�:��pk�(7�����I�m8˘b�^�0G`���̹�< 6���r$7��Ϊ�nɌ��Hgd�B�� >�:cMwj�g����̆��>��6P��W���)u�Mjk�M&�ʖpП��+qDv}����~���E����_#���t�z���IA�ď@�Ѹ3���>���qTIX�W�r�@켤�q)��{��5���w�L���s�A�1��>�N-�A��c�1� ��E	���@���5�q(򹵵���M'sc�+>�j���q�н��pQ�m�;�,�V���y����}o�S~!�]_�ʤ6�[��,ɩ�K��ܵ�"�ql�v0*��G�hӃ�hX���`zxARi3
���ihݙF&��M����m��QO����9��P�#-�j�赱 �W�BY7�k�޹�Ҋ�0�o���hw��ƲW=���+�#;ِrTM�%�7�W|Y�c����>j���թ7\付w�J�o`_Q�,��d8������C՜��g~��W>�ls�m��r�]}�ɩ�|pXy�͉0�r�3ˏ��}O��9�#=�����������m�A�/l_�.��T$0n��J��Q�8��Μ�]o~|F�7�K}�qb3�T}�_S�C�0��L~Qb��`���2�N�熫�P"s5٦2(R�������E̡A҆�ՙ�"Z9=_&�F�I��*���h'�����������`K#F�td�,�J���'������~�J%�H�ʊ����Fs擁�	iSГ�`ԛ��7b�Xw����	0`�e�)�EHtY*C�a��A&����X~�׿�k�L��DKуY��z���n�/�(Hxi.#̶ �o=1�6���A��t������-t�س>�/[�z��%b��O��|)����Aè�J)�yL�}����3!�O�,w����z��+�l�P��i�!�]�]Oys����p�1�:���<"�p�b��8��4\�8�K���r��i���-�Miݖr���#A��g6y�>�ΌkKw=q-'���#\��I|����F_~yf� ژfe��5��U6�+$q� �d��4D9|8�F�[lW��� �v8�(��A����!P�ĵ���o�k�2��j���]����t����y�b�
�0n�q
E�S{A���Н�����+�Tb�n��:��H% ȏ˨�F�v��x�U�_������s%���|b�m�{�����x��^3-�V�l�&$��әK1����4۠*�7�! :��W�6��,�a<�l_q1�q�q��    �ʝ��W*?��������޽�ۨ��.!Y`Y�7���o�8�=.��E�����V��M{)H2�O������?�8���o�����z�����u�8�}�_�4����ǣX���1߳m�˸�%�������Lc=l�9�0�"e�ߦ��-|��/ɶ}���Ϻ���M���6��?����[�����|�����?�տI7��'�T�I���uϔ�=[��+z��h��������hK��*R���h�W����X��"����q��HVtY>�J=�o���*�ie��7��l4*���lc��8��ypm;l���m�]W�$�,�#ц{��Ӕ��$�H��hoӴ�I�\e�`�9Ϝ?��`�3SO��W������E��n�[Ygٸ�1Jk�.ċ�LW0��z>������_���Q��-C�jϥf��4%˽����ʋ�(�{�/��w�[�l��$�����GJ��3��@A����/Q���%wC|�<t%mR�k�@-�8�s"N�Wҗ�� X<���^�#B��^B� ��b>�o�s����H"�	����������x&���5���z���C���@��U���E ��m�a����et�����K5Բ�+���h��q~��;m%�ӝ�l���!DmҶ���ftܾ����-a��V8 �:В�50�~�<y
�8��c�#R�����=�6؉�g(Is D�f������_̟�HW��瓻źR��]_MSP�����H����F5e�T�04*H{3���9���`���~��(�wkV6��1_���Ĭ_{��D�����ڶ���̡��ߗ�\R����I�SU��F"�<��2�__)f�MT���a��x2mb�}�K�ϧ�|E�V��Q��D���̨\hbBaX����*2 �!ݼXO�F�����$�����Q��Ԯ�o8H{� �����l #>2�5kݸ��)#cؑ��k-H�i6�3��k��� 3��'(�zK���������#�"a7��ᛟ%K�t\��l�D��gh��k�tD��4�4�3 �1�Ö�Xw�~g���/y8Fa1�Tq��>����n�JMg�`�<J9�d��#'�������������,���o�ke�G43n;����QZVH�ψ�c/�����%l�B����K�o�X$|���ւ'�v�鍢�-U���{��?P-����Ř��3ɘÎ����|`c��
>ISQ�.�\�}��Ө�C�O�� ^�[ax��.�����+������A�����QW��AI�%Y�+��;��iU@P��Wa�ؽ����e(�;�7����X��Hee����b}Z���;{�rY^��^e/!�a��ب��2
d�#^j��K|�s�\�qe�E�z�g�-�����lzAֱ��W�D�qu�_���t��~��ʖF-�V4���L[�u��҆)��?2е�U'�y��L4�Ȗ��J��/#�;|���)A�/��;w0�q��	�R�w�C�d�����BW�Ф�"�M�C�~�.k�ڈ�GY�Ru(�=�~D2��O��>���3,N�{	0���`#����^b�����c��mC4��d7�����c̨,�)A�Ϡ+���*�e�V�A��ۀ��-D��r���Of3z����@�|��zEggN^��h���.�Y�.��9����hh@$9���0N|!{�m;{������}p`P��l�3����u9#/(���ɯb&��k�09)��(�[Bç����Ev��іC��*u�c�eA+�}
2��Y�|%�`���h��7U����e��� "c�$�J�IXji�^d��'�'mZ>��r[9����FG^!@%[��ëq:�3��!��<n�o�r\� Q�
� /TJ��D�+K�V뀸{�@����<7�Ҁ�C!�6:�߭��G$��S�!Y�i+�})�,�b)��ۯ6�����;	H�ݘ���wN'�AI�#�����q���26�WƇ�}E���n���b�죉AS����L�JI�ԭm�l�����vB_���@UZ�~[�I�CaBY<����[��Z%��g]�rh��R�ٳrg�`�v���o/��7p^��Sxg����ƛ� �E��G��Ŀ�}v������.wo`h~�&��b�5;1~���5�k�?Æ�r�~��M���p`nG��*)���S�jQ��[��D���G��& ��S�Ã�s�-&8	��_���tb��>�h����` ut�{ay�C�a.����,��mʬ�'�ߞ��.D���lm*����,L�-t5'5�c� uSW'L�a����s��+U  ��ް?}��M�͈�SP���ͻ������W�����>����҉u��b��_0��-�m�_N��(U���KO 䅓��heNC���Tv��ur��N|RS2��� �p�Z�r��''%�=ؽ��
3axJs���<o@;�|��*Y��}@rf��f�o�!rL�Ga�_�j�����.t'C�^@uu_�_"�NΖ��I��j�~�}Jb��*c`4�*�G���x�!;�IrG.���U_�;ɔ�Ckɯb�8Q&��4�G
⽎y�jN4��دmZ�Y\���kKo��U��������yrx�V�v�:����2�=7nc5A��ǁ����֏�R��T�X^Vn&�)���V�G�����'�|�l��O���W�q�Ow3��A���S��!/̪�@��r�m��������������m��˨��� �:�p�����=����7�U�K��pC3Y!@�U��W*�$����ȧ�A�{���WÏS����_3&��'⛪�����]����}�I�|�6�9�q~bxi�|MU��g*��Q��f�<���y�p(��9�зZ[Ҳ��U�C��}����vٳ��Z�}MA����55rb��Oa�Qܟ`7t��u~��y�$���<�޺.D���'��" �SL&Q�\%9�L��c��zm�*�)ɺ�&�)U��b�'�a�5+~}l�I5��o�=b���|�)P��/�c�G��y�b��E�r��r5��l��o�Ě^%��v5�A�6G���r�M�_NuY�`>�$�'�	t�� 9v	����4w�:���ўBFx�X�5XQN�|:s�	ϑ+���n���]xܽRQ����.�]���F?R0��I��Uih��f���m�5p����z��\��Ԏ�1m�M�
���0)<���XG����Φ������ga}�Z���ŨI�w���O���ǁd�
�lAK�D~�p��\��?:��z>w59��ϛ5��S�H���H�J��݋�H�=w��V��4rVJ}h���p�v3�
�h?rnw�ҁr�w&����W���~�P�;��+� �������`��{����qx��)��/�Tkh/�n�P���Ƹ�������M�7l��!����%�~H�y�N9��V6$7���>3\������tC1�TEkƬ���H��	x���:
��$X��^���Y��g�DTq�����΃n$�	��ߣv�|:�e�=ݔ�^���S�j���g�E$���)#������ʢ�@����5���K���\,rz�����r������.�Y�;8r�K�`��7;�s�V}�zA��V|3���=�z G�-���%p����fRD�0��p�W�=�h<���V��vG���
�<\r�锦빁��ucV^���`Ӥ4�sy�|(M:�!�:]{K[h�`y��z"���BpS�hd�oa�K��!gy��G��5�d/q����b���N>
��������L@�b~L6_�>�g�oLF���@N�E��z��-��9��K�4a4�.ط���ަ�t�������j����c�7?�D^�D�Ҭ��9tq�E]!EX�"m�DJA䎯��)��pp���t6yu��+o�G�'L�]�R��R�	Mұ�!�ŷ��!�����K�K���l`,2���Χ�e,��&:i���z�ZӸ���e��A�̭�^�    ]�X�)R�	��$����;C�	~���_�R��[���r�I�����;�����p�	�0�I/2�f���Wq�a����jzH��I��E�M=7����^��]�Zl���f�7,�ݤ�Ef�ݣǨ����1I�y�yh�ߺ|�N�����3G6n`j)��Ծ�ΒVe�@�qx�0��|�d�Fým#�c�׵�[�d����Lm&rQ��EڣlW�� -$_�% ��n.�ϵH��_�&;
 ���_	&}W?5Nkc��3d@���S�3�B����qDK��E�CK������Y��G���$!�~L�:���~�9�01ҏ]�o�!��~�+O�6O�P2Gp��	�nZJ��Y��!�߾=ir�[�X��{Cʧ�(A_���U?�"F��)E�P�w��^��M��x����j�D�y|�rQ[v���Ѡ�W���D��չR�g7��2:�C臥�����E�'�Ω��&��3��5��j�I����p!�(B(��n�|ۅ~~
ts�6��Gl��̗G���s�>�֓�q�{�	�"8���?E�v�/j'&v��>=�6|��;g7�o!��{��ƅɢ���p�_�e��}Y��7�E��O���"4�oU'	="8�������.*�������Sǻ5�������Q��w��+��Uد�;�
�\���}��7�Xv���W�7i�;�j�%	 wBwѼd`�!m�K���ru�m�6@)��ѕD.��!�gxq��?���Sm�
�<���#�����?�}E���Ⱥ�~��5����Y"{c}�V�t����-߼ʀ;��21/~(���A��iI2��g��=~�r�h�P�v+����ё��o���[����������*r�ON}d�0:�؜�t<�)]0�`��^�P���F�?+(�L� w��L�^Jf`I�<j���J����JNҍ]/ݶ=������W��!^�6m���V����{2�O���8g�f[ճϧǾP�P[D��CG��Wy�-]�K�rk�/�e����G��؉kg/��x?ѱW���������Ҁ��YLc�ߩ�	Y��������g Eu�7.3l��y�Y�@-nWW/����sk��aXD�*���0�ٛf�[l��v���Uo�Q�=��e��5@��@��r��z��c���L�n
�ƫ���w��7���S���PQБM���>>�0b���U@s"ۖqDZ�b�}�$�Y��<i��$�x���
cM߱x�~V3=/����ظ��Z�ʲ���^�*տ"N�P��]���v<�`�=�ڋD�
O]b�b.~�8'_�Ċ1$�?�/;���6a�*"����w]��"=��?��Q�^�y����)I�l��E��A'fZ��N��P��o���|״xL�郥� �Ն-uA��YX�Jʆ��vɀ` �N���Q��"kbZ/l��}��]�M��b���*>���_'�Xs�	��{����dx�m�Q�Q��qF{�< �\��H�؎~*�w9c�r�P�V�'ވ*���;���iS ���fP���؅��E܋.��b	{;�4�yQ��9�>�78����/�MRw_{�0�"E�^/�wb_����Gɻ>��'�@�Ln��L��~>����+�( ����������B~��6��D��+�k�^	g	��$��p>�q��WG_�2��)Cx����'�7s�V�K�����NAȫ�;���[��EٱH8*�2� pR��TU��A�x�#Yg^�/b^i�a�[/�r#!�W�O�'��A��� f��������?���d�Rj���w��<�]"�q���Ǯ�@�-����
(z�$���=�������ۯgތF$hQ�,3�̈8�\FF6V��?���­����%/:�%���y4��9�n�� ,)G���I�|�!�=��?��p�A��U���Y!Z(a��UŰ�yM~Ia� ?�[�:H�Y�/_WM�y(�L��������3=�U���:Q b��i�-�OG�|'	���Ę�Uns�-� �}��8�6b�Ŋ�x: �¯���u�m�"�Fa�~���ص�o<o7��&ډw�)$�v�-��<��D��{�X��{�S������Ol`�:����$��:�et����7-= ���6�zHn�x�8D��'#�!26�B�vI�M��%�>�u4��Y��"랺�۬��&�`
�<v����	���T��h��1L^���}�m%�m�j��b^���NLU��FtJ����- �i�R~�5
tX����H0D�i��!��f�ԝ�d���64�x���B�2���ӹ����8!�E��d����q�v֪L�;�%�7Z\�;���U�@ڧn�T�a�d�1�C��tت�?�(YTg�,�D��r]a����d�P�$����7�K(�ގbks�b&� �Z7�k2��7p��~&ُ3ň
�7���3V~i��_=0���fH�po=�2jjY�3������w��O6#�OH����Z �E��A�M�ԺJ�m��BVy=���B�E��?_��I��A�E`e�T�#G(��U8�����u���!�k�~-�n���Λ�?��}
�C�
��3􀽾!g�,���%�aW�ȸگ�4!4�O	=������&��&6V����tԦ�T��H���9.f�b���t��3޹`!�mx�t���&�V�7���C����=��B����9B�Vw�S.xIF�����K��FV����%I�1�"�-_w,JO�W�|� �z녻��\.����%��<�
��1A?'�d��|���6�%�����r�C�Q]��!�	���⹻m��n���A�@��:5jOBD��P��*&�#{��m����y�KD5d'�=�5m�,"ja����`����Hi����!��Ys9�� �_�V1��]Td�_���ި���@:Ar��eF��������%Б @ҕe�k����L�0,n4�ނCf���)�028��Q��P��H��,���$���8C%�����$�I��p����_qe�gࣝW�4��b���?���p��^� [����"=�Uc	d��#r��<�R%؟r^ ��_�8���~�n�]d��V��㸥�,�*�f#��5��!�x���=��z��ιW0+)����bzUs0�`;��n~�r�C[�Fy!#(RD��|�d;�=�ϥ���?���[[��_<�_�T0G�
.T�-�Ө����׿v�_E!1��>S�mM���n��T"�w'��.�cB }�8��E��.����?MA�� �[�ǜ��C�m�a>������Uv:V�;��/���$o�6���K�%B8�O86s*��xf�%G�^"ը��:�Z:Q�f�5"�8�D@��5�K]�l��bz��2���a�i�1�ps�V=�giC҃鹕X�F�"��(���
ѝ�4��x(��E�`~И�t��?��CNAyGo�h6BQy<�<�DP>r�lMl�u6���Cō���t�]'��
>.7�j �]��������{��-�ѱzu��`��2|s#�x����}�6g�}��E�i�!�O1��aZ����}�/�p�,�z?���X���E�޹��	��8̬ �W�Q��i���B�a׉7B������_��2 _���Ѝz
����JƦ�� (F�c7�nD��O"1Yhn#lS4!��*A�:	�o�z5��e��;	G�4+�z�2&��q8���>'s�.8�zE�����z���S��n�R&PWd?YNf��~��W؜����<Z~i���v�s�$���:�m��H�$�P�@�h������Z�Y�%ק��)�O��+c,�H_/ύ��!�t�8zmY���q�-���"�Oߖ��_dS$��M^�;Y�]d��3�1���"�TD��#P�/P�,�B�u�����J���J�w�0�n��+_��o�}њ��
��(4Pba�;��6�~��rt�^WM�g
w`HSV�&����m9i�L��    -z��x~G��V��=�b��������P�C�{��A�&���DʋfG���Ŧ���!�=\,��w(�l��W�B�%G����j���]�t�_����%V?Mـ%P�8�s�=E�/�����B�N��,I�����ۊ�{�pՉ�z	��qJ*9�|3��Td�"Q�u-�ه��D��߿����q����]��D�s�ҡՀ7�H�#6v��x	r��()����JO�Г�&��ǺD�6�M�%}z0Εw*H)��e]{�§i� �� ����@��?�a|�C]�q��E��J�����c�=i�>��{�>?�ŝ���{���=�q��t��ޥ"}�H����~�P��m��c�!���I�V���4"��b�𥐒���S�W���_�'04�=vl�Hˌ��k��{ЇZ���a'��$���Q��7{��WN=K�^G���i.�7ewV!�J'�
ۙ��.xM5Dܸ��Ζ=�6�.ꆏ��uq�0'�@Ǽ����ա3Ov��c��)�\W�XCC�;�6����uҵ��@���P���h��uZ�0�l62~�V��v��§��G��/Y�Y�����ze��7�:fp}�l��ʼ��ig�RpY ���zy8�=rwʟ6�C.0�]':aO�2������G�����$O��ޚ�T���k�m+�o��v��z]����*'Ȝt�)���^�{��F�k#f�)HFD����B��=,��^^��K�G��W�&�#L�@G���+*�`�J���@����{��1��|
:LǨ�߈�Ǿ�4O��l�����E����F�'�l�'F�6ۍ��`���L��C��Y˃�~Cn<�}U�����a�)�֌嫔�d���� ��P�<fx�m��Xi��Y+��'��I�M�!ʏ,A�a����o_<�ְ,�d�?�xg�8��_|���N�M�����޺��_W���������}0!�߬1�:����f,c��}']���� H�������G�����>���}����?��_;^Nq����_�\��ڂ�Ѭ�[	�ߖL˘�o;��.���0��T{�}T���eW�����i��p���p���� ��,����ߗ(!Û�o�o��Z`���~f�����d���r��s�4Lk��r.�S0O������p�<�9O�����s��}0�/�s_��[����c���.��u7]�� Εz�V��^s�<�7桔�SA���v��CB��U�v/����Z��l�W]/%TY��E�|���=�`�H�u���/�y�������+��.�3S�\N��ޜ�͹�=�R�s�w��=����O�9'fN5��hgve�2���7�bڪ��W|Åv�o䚓QwtJE�̶��6V�0��x��Z�w�6-ť2�/���9��.��Ҫ�{�O���&���CV�/���X~��ũ"b3�U,K�K#^<�9S�N��%��X�^�v��E�5��E�=�e�w�L7ǜY�8����p�v�]�d�M��τ�o`=�<���Q�\kS�$���K�W~��1�e��k6^���GA޲�d���W6��Kgs��G��rݢ�OlYsF�ͽ4*�CK�l.}
�3�� I}�u�E�:Er��`�����M�_>�JL�s�#��3^ R�@dG��r`Z.u���y�u�g���Ŧ��]�x��1��ŋ�q�ڗF�w���~bn���$���3d|�1��ʐل����8N~�9
�����M��\��XOR�/�ܳ7L���C�7�@�~�"��ωۘ1+gEє���������f���cb?jb�:��D�2G&T� �-�]v�w|끐y�h8�M\϶Y���.�T�c���VN"۴��D1���g-���R���~��=���*�7z�V�|�^LV��5��z	�z2e]ؒ�b�ɔ���!ظ%/@o��f(Ȑf�GKm�~�%��d�����c�jv���ۥ0��U��t��mސs�ڳ�?��bE%�u��~m��rO�v�J�Kl2��(M��W�j���5	��d�D���,�T�I6��\R�J���NaXy���!WYS�ӾƮOt���0;�!�,ṅ�v�t�#_��l!+�5�d�[���'�	�I��>��qeД���ժ�q��M��k�h_Dr�|t�Wf����W �R��3�PQ9��h���'�A�a'G3t�w�ZW���۩k=�֍��ߏ�ERJoa�J'���FWT���߱�.�0��"��5�1�!��Cl?8�v�Z���Qyݎ���?��jO�C�t$���-�v�t���4�j����UB2����3ֹ��q/�����a��!��U�_�?�Ui��2dq4ɸVχ�����<�gނ��¾�2�c��,��WI ��p�܇�k�KY�4���q�0����#u�
M�p1���]�-��Q���l��FчWͻ<�Y��G�
m����	�/��0�h���F������E�sU}"�8Ն`)�#G)�=�������cuH'\�?�2��M&��/��j�e��:f�s���*��� �K��R�-eO�;֝u�2���� �8�zyV5;�Ɣ�ØN"�4�_֘��XZuʔ����wNΘ�����n_y4��<��3��z5>�����0i��+�|]S&��%�P�@XOy�a�u����ȥ�w Q�g%k�w]SV,h�|2����m�0����߾���^���m?���9�*�c������g����yJ�c�Zv��%����a�t�TGq��C���X�L���H|��N�ͳ�s��]QW�=��hv��$��m5W$�~�
�z���C�)xbDuC�2�j��Ì]���"/uϒN8�U����#wWyɳ���گ�mP�H�B*���}���-ZOoȂ���D�=�؎at���6�P���sP���p��P���x;��|�w߾HL@�.OÀA��[b��fVܼ%P������������,�$!�	�W1��j�	 �S�^�a���;�|��1�[�1$��ś;��f�2� ���	�`-����SG-Zz#��%� 'g/���T��^���"��u8�=?��-ad���z�ij�NՔ P�ۧZ ����5��4�ὃ��`�)+}U�{:;!W9-���H��eLT�H�52D�����jR�s��nw��?�o�Z�C�c���&7=��T��-N�{��ۓ��i�.ZEHE����"�:�H�q<H�(��[�~]<����z���Η�*w2�7Q�2��LW�y'y�Ő��OkO�#a���fd�u��u���g.Y���^�\��vR��ݡYZ�b����/_��v�jn1����fx쮠L?&H�`.�����Y16�Q��jp��^��N�bdݽ�p�B�?vı���+��6���Xsw�B�UO�#ep�F�1^��U���&ٚ��E9�ux�����R�x�p��
�)W��q����F-��@W@��񪃋}b$�kX�j>eʢ1P��|�A�0%�:3���'!̆��־����7�萝�m���ua�nM�`[�0Wm��Ih��KI�f�[l{���{iel�=E��(�$t¿��z��� ��'>�MǬ�@�}�P3���)K �_��Ǧ��ڣ	����4&B��˹-?M�t6t��I'�;��x�X�%���e�����<��QwDn�K8*�1`�I���Q��2#�
�exdm�L�Dr�4bIb�5���KZ�\�jxU��(��k5���g�S~b��"+�:c��/�$�Ǵ��}��_� B�8�iRP|i��}m ��3��,!�X�����m��xF� �EB����DA�	�3JN@�1i��;�`�`k���GQ�$�8�����`b�-�\��e	kM2+�<�\�bS�A���Q��C_�/p�y��=5��]/҈�&�5֕4d(5�](�䒢'��"���e��o���1'��a�xRG�kL��s�S��r}Gx���^�*�P]�,	����]P��
QCD��h�͆    ���DSޡ�/�,oZzٛ$�^�ϧUqb���)��d^���'�]ޕg]��_��O�߀�g!�FK�d���KO�Hz��J>��d�Y�t��4�T���4�Ƈ���.���� W��.p/��<�$1q(��pIހ�Q����{bq�^��ZgS�����5��o�����s�e��Ƴ+�*�bDb�R &����p���A�*ݖ6�mI���M�j��\��Y�,R?���%��u�I�������JFou=��<%%og�F"�!|���y�s��{N�b�u��M�<�@"�� )�w�s�L���8A���ʚ6��d�{����Xg�ܷ>������t `��R��9r7����h�n�)� �-¿Α��� _�|}��1�0��']k���i�����QzX� < ��JG�u��"�r	�\q����(���3��~ا����1|tr�\4t�?�K|~ùTK,��2�3�ᘝ�ŉ����]/,�<�0�p�����4�|���"�̊{��p���C�r�bB]��hB�Dn�P�P�9��G���	b�c�4����A�c���R\�8�v>u��i�a�#r�?��m:z��֞�J* '��фV}4*���uN��lp3YL-T���U�/�Ц����#�5�-t����ɡXQ�(~-�ŋ�
����{\��<�q��>J��o��d�!5gb���1ׇT��q���I��i�x��<MH! ���c����ϴ���1�-���~�W��OQ�B���V�0�;Y,eDy�6l�fB�Q'�1��7��u���e�e��U)��Dta ��oC�&Y���$��I���T�T��S�̓�����-MO*�}~�AӣgN�0*���^j-����lHs��8᤟�Lf��"L@lx���p��7�v�neH������i�O��\�Z��m����I,�(�;W�ܥG�4.S�f65�wD7/�>P��Nt�-�䚈ѓ��7�i_\؅8�YFi��{�Q�����xO�oVRb���^�/���g�pQ-�(H?h�#~����,,[G��Ś�<^��8ФǈM��Lq����B����ᷠ���\�/���ʚi(��h����AX;:9��%Æ~�M[z��_C[��h9�oFC���9�x^ �|�H�g��}x��P4�!��{�84�)�Jz�u���]=u-2yQ��/�����;��:�������(I��d����mů�o�������(wO<Z�� ����2�R���x�f[�Td��54�GQĈU��8�{�#���gzq���$�M)��&�������Ӈʾ@���3�ɮKvgG�`��#E�xc�`U~֬%�Τ~��hMˌ�Q����!;�>�����0��r������	����*�^�&����Hkє6�3j]���­��,~��S�Ф7��'��J�B���kD�}����_V����7jG�6�v!�Þ��|O��S!g��S��2�\?��y��Sp+H�����5H��K�KGf�����7#X��}#%bGI�V6����P��ߒ���X�o����4+� Q�	἗-m�Ĩ��K�Õ���������Iru2�~�22Z�q��V$������^���9�m����ڍwT�*�1Y�hj��!Y�ԅw{�m*<�7��nM�J��f��# v���d����6�p�r�������R��LsÊ$�H���5��Q�JG���'��3�֒?R���0����̒���â%��S���*U�;�c}��]}Ш�(+�H�^�+�L7�s�|�	�;�9��1T�ޏ'(r��^��n�-���j5;���o#�� ������"�T]�Ƞ�k&���WzWӸE�|����ǣo�敔:��Ed��m;�*IPJ̯��J��:��*���[�/o\R������avH��}%o�p����˸���{̊6��8X#��v�W�7n�+�i�p�"brX���`��Rp,2�_�l�z6� (�٬�&%��]���E�����Q�Rb�z@+���@�5�K�cʤp�M�k�ɵ����J<I۹3uf�d�+l.+�[��#��-��!8�Ǵ������R'.)v&5�E�L��4�9�3�2q��E]d�\�3'�.��N7!�����iE_-���\�_�u�&6#�K��f���hG�?��\f�)��39s�/!���\j������D�Z��|��8h��q��=�\��Lܢ��a5~�ל���ZM�xmÈvb���3��~�դ���ΎL�ԍSKo�scH�G��w�T���F���[=Q���!�5���"-u����7�N�^r���%�t��.ƹW�	Y�Tq)�A�bˑ��Ĉ5��=w�;M ���u�횙^b7.|���+��LJ�h�<����S� ۙe5H@ui[�`�F0����5EU8�_��m������7~t`������~<}�k�P�'F{���T˨ ���"���Z8}&І�������v�Sb��QC�4	BTV�E�i_�\}Ғ�h��;�0��b�c��م��P�w�F��~��7P��j����2�$uP5�I�>epg@|��K1ⷙ��FsG8���'�^����Y�e��Ծʈ�d%�j`��M�Sy��V�M&�R�f�F@D�Lt<`��I�*��V�)�mA	n+���g���)=m�;��I������;]2N0��Ǌ��?_�e�;Y�e�R�(64?a`����j��l�`���oT��s=���6F/?o�cx�wh?t��R���%��x�v4�m�m_�v�)�����j���:�ZZ��3(�ȩ�~�2/>����q�9�L�N��T�V���@(,.<W��
�7���'`�"L����hԌ������>�uS=�:�]lp�2�]rC��%6���&�X�X�b���X�v��%�r������ո�|�z(4&Ow�t/a�k
�.M��ޑ�[F�he@�
��D��3,�&�)P[yD��~5cF�h�NSC)�H�9�s�!�i]�o�@J���Iϔ�����<P0KEqp�\�9�9�I��<�r�Y�����z�)X�h�	y�DrLQ_4��� ����+s8�`��Fͅ�I��Mm(�^b �o�V���0q�L�E��b�H\�t(�@f;C��;�n�-@�=�ζC~1O���0}�˝����,~i���ݳ�$!Z��3�о-i ��U_���!Q ��$��6ȳ¤^�(�GF^�4���;�A ��v=�6���3�V�`#c4\����k0ō�#ްbB�N��-�ӌS�(����%Fp�k�4'�K��W�S-7��住��.��@�1'�G�.6!�P�.�jz��5�����jY�CӒ�a��L�&h7ɝ@���} '�D�)e#4�$�^H����;[�i�p:�w����_�c�����0���-���z�����w�u�3"f�\���i�d��J�˺LP��-OY�r%tO�:�u��G1������%~*}g�9P�_��1X�Z_4�z�cHh��DH���Q��Y���Z���qI�N��Q��3}Q����ҿĲ��A\�?}+hXy�j	o i)P3�e��R	��էB�"v
�lvfH���{�?DhhîS�}U �Dݠ��N�+�[h��a���'�B������p�Ut����:���Stf�J�8~u�Wz�P��]��ꝑ~I,?�9�v�~O��� � V�Ѭ�7����>|��˙7�s��]�V���ʟ�J�P���czf�m�<�
ͤx{~� ��hHz�I�?��ͳ����)��6ۑ�='���VK��s� ���Yr��z~<��x�����4!,���=ӿd�F'�A_�	Q�6����ld��:�0S`_H�3N�(���R\�g��K�>�R���+ͪ��)ۀo-�N�Q�	5Qtt2�F�{WXK�&y�u��7UjQ�f����e�B��]�qa+��.�͔7`�K�����v��D�|��ғ�ӼU-��1��RW���B��A�EX5g��$��P%C�(���h	�����b����p�ac��Z�P    ���7��n6��ַzT��'�З���o�D�����g���i���.o5I� bw�t��oW~�}Esپ���SjyT�L�*��#����o�U�H�"��~�z^�1�0��	؉��1u>Ҋ)���˺і��vE�5|1���з�S��2��
:{H��MK&#ey�M��e\d>Z~~Oa/.��Ku��Q-���װ�&P�
f�������+�X��u��Nu-��6�@;�.���?�M�k�
/]�����<����󀻄	y�~"�nKX閍?I3<�ڶ����^�Ю��~�91�f���m̏4�Ex�j����9���̚M%����/�����Ӊ1�\[�K�Ŋ�Dc2pe�����Fs�! �J6�*�k�|����%k�p?��/-��	3�4O˨e������=\��c&>��)�6��mχ9| �����d�u6r{2Ʌ�a�?Ŭ�@m�	�ҩ�5߷�v�Nw1�T�0�b��J��T�u��Ԗ�Hpb2�/��<������Q���6�Hb1o��YH,�ܢcH��ig�w�1{h1�c���	&��[�nŴVZX*q�'�ix7�R~U���U���ձ7�w����B�ܡ���G��t+�!�����/` ���sGr�9ɽQn	�NX��s�m�������ŵ^j�+C�q܇�h�9��@��`ݢ����qq�� �ط~��/e����
}0��kOb���Y�u�(G@qʑ�v�5���h��*����^U��&O�:	�%Y�lc��U��m�.�%���G�O�"�%��hI������K�Ӈi���Ő=V�W�/��̙B�x�A��Q�TV�W����@&|KudЇv��IK��z0�j#��{^��4SΊ贸-s~K��m(�ykp�uaP�vm��<D�C�.s.?��,IQΚ&����v�� d9"C} Ķ�zQ�Z�K7�k�Ԛ�a�ض���ӑb֜ Ԙy��v�5��+�H"�}��;�u����D�0��i1�ZO:1N���S)���nQk�=��ƅ������r�4�n,'�B�m���j��[�Ps?�V��_��T����%���Lj;��=	�-��Y$�KL�E��%Vі�| _"Z���1)f��M�'S۵S�t�Gf����:}�����Y���&�DbJ�U��)�=;wCțk��Z~ߏ9�űmKX�a
%c��%1��b2��j�tۭm���DH&�B��]�-�l���V2�ɋ<E�$�G�'��mo����k���lZ�$H�y������ZT�%w۶�1j�pE4Fm�;d4�C�YH�*���5F~�w��2H���A����#�ϻh$3�)�+�����J	�_�)�މ�C3����L�h2ˈ�/`∘��E����q�&N�yl�ȟ�dY�&���1x�(I��c�?:lΗ>��A��W��l7�
q�v��	:����;`��U&����P�b	j��R�,�)��V(fl=��v��$v��^*^W�i�迩u��p5N�z���_�����_���5_���[���H�m˗�������������,D���v��4�Gr�#ΎxH������E��������?�z�ӭ���?���Pv�?�z��n��W��U��{�w.����������ѯ=[�^��Q���������m_���d��np����8_7�I��������Nz�ƿ2��q�{&z����I��Y��|�6��w����7%�/;�[�c�̿��LӖL�Q]N�:�j�
������������8Of_�9+U8�Ϲ)'�XMdp�	�Z��}�����������4���W_b�Se��d�s;g��;Ɯ�q<�puq�9�����5������`�h�d[�κjc]��Q��ݒv\�:0��X�Ν��'��{�+II��h}d+�\i����o_�v
J���L;�w`iV<�؜W#N��|��Y<s���z�9f�q9�f=S����Z	X �z�\nQ�j�`(�K�L-�4�+ތV���i�������B���@	��(��@��fK��)��i�O~FE�Ad+O$��/;��7�xZ�{K�h�;��e)F	G�h�hLvQ��;΁� W��ٿr�r2Z����W�u����{�P��b2>�w��^���'�����p�
'�<�:�Ms��πX>?�9`�>'n�[��g`�j�<��W� � \��{��(�%�>�>��d�����K�@�٘~YM�*���1']W���|#h���b�^�$U�v�D��QC=-�ݓQ��A4u3���r���ύ[Y��W��s�O��ԯx���gG\���M��_�H�4Lk�1�|$N�RA�\�bD�k�R|ߣ��mWjL�]T��m~���C��ݥ�{]5ֽ�%�)�H�5c�b�hBT��6Y�r�8i6�cT/Q�L\��E�a�Y�x���EO�U�|im��Z0(�V��r<��N�h�J��A�g:q彯iz�o��Ӑ��w�$mloB.)��Wj�r���l�ӫR¯3��/}H� � �C�����TUO�j��^;
������}<��"�
�=�?㋣,�wxBh �\x�k��y������|��8���$?�Q�:4t����K�8.5�v�灷
�J�u��2}V��r���=��O��W��9�@�?t�������sv�8�p���ùհ�ޓ�9k�z^_��L�~]'��4"L����S�%������2ۚ��)Μ�4�｛��<}��oܮ�ꈞ�vHhJ%�+?�IG���v��Ѩ�9J~������y��R��B��H���ר:�� ����wW���,��(vg�MT�B��p�xo���2Bhů.���
>���1�Ef��J,5Jl��ٍs	&��o�n��N����0)�6���e��4�/�Q��O?��H�����ȺM��T�h�lP@�2'������U��2XS"�]�f�1G��kH-��6�T~�����Z��-4y��~hr*���~������������
��9I���ia�l�,"0_}�^��m���)P��ĩ�`RA'�48x� �b����E���Ĉ��NqA��@����wa�s�N��3Ǹ:=�u#���a�:�|��Q�������`oŷ_�᫏����豏JM��'��P�$V�"��ȟ�:~8{��XUX7���o��-!\$6%X�3R�HA^�\�픘�d���Tl�������o�Dy�������I����]�u2Σ�i��I�s��6%�j���L9yT�϶�Y~�9Ҙ�&H��`@+b�&2}B?z������C���m��4�A�L�#�d�xܘ�g��?oލ��@kɝH�2��]��%�hU��L8s�5��_l��z|���"}�l���]������-@��S��]dt� iT�⠡mt�w<㋠����עR-�����_�ur#kJ[F�����?Z};�z���e����aP�z6O���ů��6�e|��U���j��f ��b6��n�A�?�!�(۵zOR �4������B�&���M0=��LYƬ g���+��ybK2J�x�e�C���eY~o�)t�f����S䶴ۼ^���P-������#A_�����=s��:%�c8�O:|��6Au�P3��;"܅��Q 'q����76f~�"��ȏV,�ql�0��$���p��*�'$=��;���_�ն�O����TI�k����'�&�#?l�wO{���/�nc'��5���np���E�٧�\���P�~��|�(��{.8>q�s�no_�Ԙ����)��w�!����fG�N���Ӑ�$�ۉs�	K~�.p^O_9�0Xn�����Ӈ��K�'G��d�7���쯲4.e��4d��B���[�)��*S�z�.E��E�1+��D��.��s�h��X@X���Ŕ�����J&*�42�T�B�3�iۘ�Vk�a�1�1�����N��/5�J��k�O]���    �Y��J�Z�}�%'y�m�K��>t�,��3G�5'�K̀ݸ��Γ�]�*��ߦ���Bb�Y�J5%T�.��Q�A����|�B�>���Ϝ;WP�|��%����P��`VҺ���El��MlR~��з�<���+�vU��Y:r����'��u�k�F�*5�M�Bqq�!wRe�Bs�5}�~�K5� [
�]�_P�B����b�0{����&4ޏy�`��>E�:�������9լ%N�ן��"-i;2�d!���r�r���D�M�l" ��Aכ�=@t)n��t�oB�u}��	
���������U�ʆ&���<��Q�'�I�ڞ�~G�����GS[�yP�Ε��AyL��6$p� P�]�R�|���(g�0��}[��D����"�GE��m��E_�7T2�fs@WZ��q���<��N�����u�lc��[�U���5}-������O@��j��n};�f�)��q� ���b��*G�����0�$�y���5�o�Q醚`@",�6��iifz8[`���^PO��Hɼ����;��	��}C������MSE顲AX��hrc����g����3�g?Q��J��$��9=���-�����_�G~���:�#^��W�l�HY)[��Չ?��6���*��3�ɜ�ؗ[��`R/��~2��K�w�+����M�7�C�)V5��T(Ϝ9i�6ZGa84�������s��Q��)?�T���V��|�,H�̵t����_�C՗�����C_��l��+?�dY��k�؊r��FE~���>'mB������­x�e'���� �F�+]�Dƺ�5�Q3�n�k�����Y�K
Q/��(Iw/g_����L=�	_\t��3����s�V�JN<,#��������1��ZZ�ӥ���2~VR������'�S^\�7��d.�!�b���.�fR�Z�C��UӉ����A.�q6fMv�ON�\fbA͞�d�7�� ���ܠ@'��`"�hc�R*S3�égW�~���8D�`�vB�L �^vF�6C8�C.�2��_�8Ft<�5�V�3c�f��,"�
��&}��Wk���ˏ�͈��]|�gGd����2yIO�7� /B;t���Ory�!{��Sc��B88AE8J��f" }���c�c��Ì�r�]wDT��)
+qFB�4U�bW��.R���a`�J�2��}�0}�v'�$[5�ߘ$?܏� ��f�d�+�t��?�:.�+�Τ��$&zu+j�W���t���<�#�;����^N�������Â_�^/�s��0��}��;�לJ!܄Y��9�#������-��u7�SM4�U�T�Ҟ6��3ǹ�4��'Yuљkb�)�d��~<���l��)������̱������'%�����4�D���v�,s�D:�s�#$�Q*�c�@v}�������w�p����`�8�_n�#-w�k�?�*�V���@��#��qb�U_�Zv������,���?9��Z6YJiw���w6$bJ�����p.��ԭ*N5):yn��%�JW���<xh~������F���|[Խu�����L�;��ls�D���8j~P����������deD�����P7���x1����Q�s)���v/^N;�Z������~{&�����ҊE���Wɋ=o�u�=S-Ao��9����D�C�B��K}���6�n�I���j}��ޟ�o��7����gR�b ��`(�# jxjQQ('���+�O%<�"��/��vU��.e��f��SM2ܱ¨�@�r��)�����>��*�]�.�l�&x��媙F��`�4Vն[�O�r>f�/N׃S��c�<�
�,%U�<67�蔺§�A�
4NtHj�&"}����AH�s�������
��~�a����U�˨��,�m��ˌ�p��*�"����?�,�?&������~�Kt�uõy(�l����R�M�����B+G�OZ��~k
}B�ܰq�r��Iz�9��>��Y?@����1C\�8K��8֞�{0Ul�2���ES�r����p�,�%�[���g����v��E�<(�w�-Trm��SIu��T^$ �|mW�wZ�����w���J?R�u����h�_���£)�+CfJ������d(p��X	�~M3��$}��?���*��&��^q��l�뗈�@Qr�L��X1|BP���w�}��t����""�~�J�P����[y�=W�:����?���5���5�����\??���2�����<z+L��A�y0�=%����!G�\�ܺnn\��t���{��V⤲B������P�9o�'F��i��Q�Q���N�Y?���������uA�+��+�����=o�e�Hz�\�M(�ۣb�Y1"BE֚���t$�ԝD��H��	��=_�t?���pg^�����HI�bUoP�®;�Ý�h��U��s�<�%�����`���'}b�k}�EAGɰ+�������6k>]���q�K��3����[�a?�Z�7�Cp�UWuO���B�*f��9�zY�.q]��jI�>R6}���ns����[^��9�z�՘��$��@ (�flܻ��z�&��Zђ�C;W�3�A:9���������w�FŦx��ӥ6���(AH���iL��`Тۇ5&s�}Hs�A�\c&�n��G�h���}�f���7 ��=��s���2����zFt��=��w=/,�2�����~�f|��u��Z��S[X��7X���|�I���%3'�wq�H��@�3a}��B[��v�ȗ|Jf��W�z?���0�o�A��V�fy�'�Y�ٖ�Q�~?/��%mR֟Ɠ?�;N6�Z�l��"��.8�=��V��Y�Z��՘�%T.]n���h�׈<�,��=�7�]���^�g�.��>1�.ۭ̋��~T����
�o$k�ual݇�2n	�jԙ���1��ڤy�" h�����`Ca��f��\�1Y�շ��C�](IW���|�p e)�#��ʹᓬa�ok<���o�d��u�\��gl.B��>R]xG�L�o��V���$��M�{uE=$0��}�)�|��F2vZ5�fI\�Y�&�fD�"�@�/V�5VE���4$$'x���U��Ȃ�һCIj�?�;`^*"��,�'��~��&<g�ԢOD�5�O� ��+��)m��즸�"�Vޥ��|IdڊObZ�*�9I�w ��102�B��NZ� <B���J2m��<)��d@r���Џ/�<��Џ7j r'A{��*n6X�k�3ɰ;�
W���X��IX��ٷ��T��LujY��n`���x6�ZR����D��f��U��!켮��Q��*� ��
�\g��飈�r��\#����t���u���-(�i��Ɍ�ƴWM&�)6�>�g���E��L���$և!��Mbɿ�q�,D@~N�C1}���־ΰ"���S6�G��MI��-� �H�.HJ��B� �Jњ~Yļ|��B~����rU@�_��TȾ|�|�qh"�bX��\�Z�������Ӑr�躯kH�ȣ�&/��}�����V)d�_�Ilm�1R���U��"V4��sv���F�Ow��H��k\?>3y���;��u��-�Jﭗ�;�6m��F*E��� �?ɒ����>wL�\����������c��}���	���	w�R�O�^�D����z�T�,�D°G>�'��Һ�v}�x ڂ���+�.�LT��Үn��%"��=3^���a�lB���u-�w
�����3҄��F���Sp΁�>Ѹ���Z�s@
��=�Ф�Q$<CM�F�~V6���hi�$�����BP��U����~�Usj	�j����|P���<�7f��`��	م<��"��e��NGА��:�n>Bv�^�!�~J� 'N0�k�y�����5�hҴ��-�
��9�p���~�*�|p�,�j�9`���y�����'k�J��_��F�f"{�QxM�:�]��    ��m`��j�R<9bl1�4���U{��w��<�D7,i�k���!l 'uM�ux6�u\u���}�_QZ�Nt�#&�U�:Ė,t�6/�Sd����(n!q���j����c�rR���7��U#�L�Yw���˜�;�v��
����ꄭ{	봲�/��	�R��L5���
��/m�[�ϝ�0��z1��W�V
 G���r?-��PT�������<��m]q��Ga/��?��)��t�t����6
����x�yS�yNʀ�#���"aK/�zI(I����OTTs��JX�4x��	uՋ�y�t0R�p�7z���KM�_H&x�دxNW5?����M���o�wdl����ò����\���RJ��8خ��z��˞NOd��J�ǲ��NC���W�WM	�2k��ʤɁ�hm��k��#��gi���;�%�������BRj*�����#�Z��|
R˟P'��2��rW���.�u�kQB��6��x@��m�1>0�*�'�g
�k�^)֢�w4�wU,���`>��7>���=�wc�/]g�4{����ҙ���9K:�R��'���8���&	X����R�����aut��M��5��X�
�U�%�U�E�7������C�V�����έ�2_גfQ¯Ӆ�m�mǋ��.]�

L�#~��8W�'�-��lET���_�i�x������]o�	�Jm��#O�u0�vZ�|��Փ�m\���V��?��3z�9�I�]��GID�#W]�l#�YьS�8�0�K���=�*���l���k�OMK�7���N~w>�2H��~5f�����72�ŶB�[_�?��r�[̀`��޵\���5yR
������G&+nոkX5N4E5��}���-�������w�~j�!�``�7=:e����NMP��]���"RMsR��Sih��� t�I�a��;E��ocv�%^�)�z`��v�-�^��:$��[�������T5�ɯ[֨����X����`��ۧB�	�����Z��s�'"]r���i��a�G�h�;Ҙ�>��
g��J��B�+�6K��k��E��Vu��9T$�\�A6�E��2Q���\�Q{+~�T��2:(�Kf��؋��=e�O��"�R 7��Ne���Fq昧$&�*��������4�r���6�_��r@߿�jR���e���:��0�e��tE�
��Q�m�ͮ�1
8���կn��uY�>ܤ`���oάQ������Y�,Dĭ�s�g�h���R������/f��^�� ^��A�6��<��>|��1�K�.�Êt����lv���)�(�rѺkB���˫BX���Z�,����U��R�-���'�\�U`<����N�w��Ն$�
A��u�Z�H�I�)�F��{h�[E<r�݋��'��q��,z�/;"P��_~�Цy��7�Y���R���5 �jQ���cƱ#���o��~�ذ�(iI1���7��Q
�#{����1E�-f�Hw\V��T!�佔��?��f�:b~��˸�'���'�0�%ҲFk�Ok=p��ΰ��5y��/5[C�i�6;nc�bJc2�ċq�Ɔ��5���OC_0-�>J����񷺚p�VR�����]�PΎ�`�.�n�Mm�;��_�z���B�lu��jw�$1�ݔy��/��%�.-���A��b3�|�$�	,���q!
�0�#��2wJ�U��o;q��*<�B�E���F���z�=-�m@�:��L��ID ��Ǹ��]�a��aAZf)d���"1���6٫{w)��]%��w�#4�u�߇�o,���˾Ι�`�`���=��{<���!��\g���Jn�x�>�'lX�0u@�uR�[;ww��վ?�B��%��?S ~��k	�2��m��Yܘl�K����̩Q���cy
jN�e���HIq�����\�}�˰�^Y��F�`	�:~{���6��������0�2�z���1�Q��?i���[���,y�gu�k=q��1i�t[�ɨ���ޕ������T��w��Y��3�������x������������˿�������m�vm��3a������}��&O�׿���_��^�+y��go��'QZ��c��?����#����[Vi����<��3����翓���J�N��y��?�ӯ��'y�r�W[�jc�bo�W�i�B�ݮ����o����]�ĕ��'ug%�/!�/����=i���09�o��_jQ��~���d���Ӊ��ߔޜ���i�r*�[���i��S������S���5��L��e@IA�Lq��AR�=�i��23���h��E/v�-5�p���N��À��3G�=��3���'���pf�Z���w�KY{�ӝ��"R�U�5�vu�y��ĝ��c}q�O�p��FG0�K4w�pr�H�!3�=� 5 ���¿���gPBaXm�̆|�sK���*��`L����Wra?�nr&SF���[�f�Wa�:��x�����&C�����F�2�����j�����ǘ֍����!Sl��ߜI�-?�g�פD��U}Mq���dm���]��Ι��k�Ǹ�I!�Kg/��@~��KA���k��ø)��B�~�l1�������*O��x���p��Eb�� �^X\���I��צ��3�)�*|L�N&߮͛=Y�{7雅�֫�E����}���B�ŧ�̌�F���*�<O%v0��r�&i�1A*y�KC����;�t��%��>�h�Çz�N�2ϋz�u6���:&9�m�:3-�#�V��'F�O��*[�|b�έNs v�Fe�Y��&�����P��
0��:����z�5��l����F˃M☻%M����]����𮯓�%��:L/I��P1���o0�z|�7�nP�V�3���%��G�B	ڙ6e{�
I�'�;������T�Oe�v����1H��6>�UD?���Z'Y��$�̴N���eV��BE;��o2Vڎ���hZ�w��/��l���|�ߺ�S����$+�*q�E�������ݜ�=.�7D*�0h�n���$�>9T~	3�_���}o�)Dޠ�8}�N�e\�L�����>���ܡg�f�^���v�	���Q/��f�b:j�Vl3�Ӧ�MC�]_(���gJVV���������T8�6ߒ�=ᚬ��}֑�ExPg{��[��3�6�̃×���V��!BN���T{A�w6��f#-��ٍ�/�?�Im�������ֲ�"Ơ{�F�{t������zR5L��-�_�5�������
���pv=���U���5@��y���?Zr����N����Ħ�����[f��l��$�u9��$��V%b�G7
j���dh�}&����W�}k����z-��`��טw���&F�n��3QZ�-����S"K�@:����e�HV�(�X�6̴��#���z�:����*�=��+�)E�"����75�n��/��P�*ɟ�����JC"@x�ݡ��j�-j�S&�vV�Yxb��>�a�j'��`V-Ȧ����� 9k�2�����{}��?nj� �zA7��Lݏ}p#�?Ǚ��b<X�GH���u&M�4��☜�.���r5N�����)��I����ӸLK�GQ��>��1�	T��|(qaG�G]��s�q]�)`>�Xk�|{Q%:@�0&�����v�w�S��d4z~,�r�W}�K����Mj�)[�����f�\D,Jb-��#�����bZS`w�~�>{U>E�=��F��|��g�8�K��FA����M�XIX��ck�M-[�={U�pD�e8(~*E;���|����-*�5�=5q���]mQ7kj�]J5�H���9��Uo�
|��S�+x�/Ȭ�ǋ��i[�5 9���0��3W�S�<��a��ă�o�,�r��$��5��{A�Sh�'�G�܃q�É>�\��4d /�M�Ý����x|{;%,����R����G��e�%��
D5nM\)��L�8K����3jE{B���y3�H����G-�    �
��q����-w��#�~-���d�>�G}�L:�0�_1\ 4ǇY{�Yt��������AN�	%x�;!	���Д*!�g���*+�`S���z�;�P,^��U �T�o.���܄�e���
8n�T�y
��mpm��O,�����k��z�>#�wl}�2ǡQe�lN��_}I�0ϰ��^wu���]�dzG�tD��*4�}}60��sgǯ����.âQ��5���5/�_1�)��	e	����
�%쎓A�#9�g��wBn^5�۷׏=&����q<s�_��a���~��N�ׂ��-�W�M�+���?�~���̥R~�G�oD�l�����*f����\��rWq3��1�b��7A��,��;-��=���V����I6c�2������&���|�R���b&��@�<��sV=OW�&
�$5p9�G����K�+��t�?�q�@�k�S��a�F�]�jg�;f��/L��۱�|��9������N��^&E'|i��OV��R��Y�_:��'f{ /���"�Kh�7^�;��9���Cx	D{��^_"��E�>p�z�(�PR�����09�מ�p����ڷZ
}��䊉� �Q����?2����Z�ȕ=�-��
=�k�ɵ����ޮ�����~�$J���)֬���A�l�(�a�N�^p�Tݥk���<��^m����Ui�|\�.��������)@��#6�̑=6m9���1�V��}dG��F |c���Ջ?a��!�]D�<=R�f�y��.��L�>\�H-����|܅x���.l0oL������
�WO�u?n�{�Ϸ��e�w���(�0>7��JnˑZ)g�aJ�;����r��@�*!���
�1V�,�G\oc����b��賬�él����AF'ǟ��(X���+=%�Nz;���!"�e��0$D��mrǇ�]�2��5�z1��T�n�%N����>y�!��5��8���ҡ�6$���Q��{|������B�'���}��7RG9�M����vgV*��fc���.�_�����.�76x��7��a%TL�y��L���3�b����s��S��@�l� 'h�OX�B��5���3=A0wS�ѸM����#���$��P��eW�}a�+d�j�!~FGmW�*^���n)uV�~��,j#� �c�zb��n�D�Na!|D���=���3�Ūޜ�aS(q �������62�G��哟�3����{������$T >t?�yݿK܊"�/5����\�iB�bP71����E��n���#p��?ܖgBe=���������'[d��dr��k}=�lwe��XF�[�}-��q�+4A�R577£Gfb`��Wc��3��A�Lk@�3z���¨IN���N�0���xQ;�v�UN��'ъ*ɢL.9����9�}�kց��n��A�֮�t�j>uBE��)��͋�x��8�v>��XG0و��m�qg]�-}�1�۬&��'n���X�h�pσ�W��7�䌻��`S���|t/�Lsg�0�3k�~BF�|N&�gu�k�M��zI�]��Z�XI�����L%wt�����-��e��s����?�ת��]�=dP�A�.��=(|��}%��I���C��x7*
~���*�Op$�0��D̶��[�[�hpP�O�0����C͒�vj�^���w�e=�M�d�C�E�|i��g"Y4�Zذ���0TN�~0S�]��������2�_o'��eY&���Kq|]W����Pu����f�X�z��)Ɉ2r2��`ޯge��� �/�����`Zjb��`�̋���u����׿4@���du�ܬv��������gt�;H�l��e����j�IG�?]�������>i�Q�N�;�zwQ��NP���IދYP�+�Re���%��6C�k��+���K���zѯ�pUg�`�>�{�Y�ӫ�
ҙAd'����ʺ?���Bc�S�#�6�rQF�	�V�$�#$rrA%J`�U�� S�����!������r����]�R��6g�W�?�O6���K�A׮ѽ7�jķ{��%��~;p����L2I�{)�vB�C�9�_תN��5�Ⱥҹ�G�x�ڎť?�o6�Vh�C���8_�I#���;��!	�a����J_[��`��T�v����Vɶг�z��pP��$���x�	��d���fa��j�G���9VJ��
ڢ��ahk���^ی��7���ƳO�3;Ŝ�p}fk_�-Fl���qg�8����S�"H"�u���V�`���ΓP.3�i_�m̠�y��h��;�Nޝ�w�����㛹���'(_����=��z�1��7dM���ݶ�ǯ�?��r	���;K]�AR�S��v 2�AR|�$Q:]�_���O��/-XG���عo�w�&��763��� h�
��+f���~F�������	HAr���9�s�������1�G��������({㖴Y�t2/r��c�P/��p�>4�1Y?�����:L�\F�T�;�V��R?/�gϕ���YX�.\ ;�Җ�G�!� Ʌ>�Z�.�,��ӣ�R>3�����xf�J���/kDʎ;R��l6?9u\p�?+j�Z��2�"�`U�Џ��pH����ؽ#��B}���v�?�\����(g��󔿾�H�HP�{y�<9�m���t_�T$�R/��1�I#~ڀ���N���O�c�$�Z��߸ɦln��^\;����sո��&� ��O�p����=�Ih5k�οf��ꆝ=`y�c�Ɔ'n�
bgWn�1�	आ.&�;I8����Gno������rR(�n��1�9h#
c���W��k�l@t�|��Lj�5��q�=i���ж�.�� ��LL�_-r�#��}P}�ÉQ	$r�ct2��7�����B�p4�������]��DO�<�U1`}��BhC
�x78��'�Sn�G駍�?_�OmD�峋�i��g������DXH@Xj�O�����#��H��`6��I��!����u�G��g��~�D��Q~:��Y���_�$3�<��`��=0D��-Y�b�:�
~�Q���
#x�>�2RН����L�C�7p��7Dt
dg,J�6���Ah���#�n��5�i=�'��-�K|H� �����/_/Q��~��Q#��] /�����9~���8	+pm����!���3�t!�	�F���FZ�I�X�N�st��Όc6fs�Z���<3��}��I�� 1�6-#o�i��)s�y�͕n8�Cno�9�j��)�H��m�q�v�8�R��:"R?&���F�P�	|0�C1q��z0̂5�w��i㔝k���}���I��qO��)P�I��Z�FЪ U��=] ����%�+�S_�;���jf'	�z�)o\Ｄr�W����|�I#��R����u�?O�ʎ2�S�i��v<������MQ�(ތ�N|�'9x�)Y�ՠ��n�D�R
�Б!�;v�1�΋_�Y�(|�|�}PF8�u��������{���h�.��U�HDl��&�K1����ަ#��Y�{l;eK�㮯�9�Zx3�#�w�'x��뛛��U��ԠH�^::g��(�)��&���e�V������Ey�?7#Po}l\�����x�^��X�*��'��ɶ�S�n�9�&���E���~o�y5�/S�C�_*nY$_�&�YYJ{#-P �S	�"Ǡ��{�"�	�H%[P��x�>�w]n #�S1��?�������|f�{wW�c+>�"�C�s��-���p��SҜ\�f��Ky�E���
��n6%�Ϋ�JM�7�B�+�U��xV���t9�����(���`��F�,����bBI���^�g�P��]D��hѼ�3��@��0>���Cnj�*HB�}����F~�0|W�p�_a��- 89�z���.4rS$�5�4��x ����ZƼa|�Y�5��f����u    �]	^�!��m!��g6��a�(n4+ �����~�м�u���	�6#�(t�tG|�بק7ؤMj����}��p���k#U��o+���j�Q�ˮL�F�t���Bn��L_ι\�o�Q!m��9�ި�jK��k���!���I(��J�D�B}_U&e�����c�R~�*!�H�(�$�I>�3|�Y�.�o%mf�");M�Q�`�(M�923��s?���0��H�_����E�]���r��ЦE�x�2+a��-��뜐Ъ�Gw���e�a�',���;�y�[�l��vCTٞ�����������l�)�S�<�XM�������<�bPKA� U(�Gz9�h����X����ѝ�6����j�1@$������~�.���<���%��7�W���N(�M�x"�f^h����HW��*Z,�$�ݡ��^���i��ZUc�Q=�rko�r�-uV�З�&��Ѳ툉��l֭�@$�B�%�ݐK7�����W̺�/%�#�3
z0ָ��	G�)�n�ao�TA�s�)1��T��~����O�^������[���q��\P�4o)�pL	{Z|������q�r��i���$O�e�j8�ڂ{��g�`�S���jP�dW�G]��m�uQ
��"�]7���l��H��fL.Jb�23AP�.y�i�E/�D[{���E�g]�0����W���վoB�Z����[L���_�i-���Du�XQ�n��u3�ك���.�"��E|cMA��'fJ{��@���	���c�����cS���~[�������+�l�����o��?�u�Ƨ��G�s����~/��ܩ�������g]��?���4��?�1��6�MޔM��k׿��e�g���d.��:�4���N(W���p�!�x�pe�pU�`�ϵ�W���	eO�T{�������v���N(�"-������6r��{�s=!ʽ�/Q���f�z�?�P���[���?H�5 ��X�o'��?���X+b�����J��WcuB��2[�b�e�$�:��(����e��Ǘ�f�Kh�^�^%n~x���5��g�';�_�J��ӿ1���>�2�Wd-����l5i����������^d��߿�/,^g�?���ZYz���/\RD����g7�W������}Tz)������XK����Û��%}��Ѹrq�J�-�n�`=��@	E[�uݘ������<�`4���58��I>�n��g�Ͱ��^-��Me1q����*�~%`�$��Z&"��wro��7ڡ�1Q9�C/���@��#�!+���MF:ܥ�:�-�Zط� ~ID�墧6�tUKr0]}ٿ��z�#���o>���������o���τ�y���H/)(Vw37I��z�����ɄR��Ѷ ee<�rRj���$-ӷ,OY(ɍE�0v���-E��w/nj�1$��K=�������`�m�����E�y��va��mG�[�շគ��������^��C�4�ؔZb�u�
���vM1�]t,�}j�Ӂ �^�]�9 @m�;_Rsߴ3SI뼚�/��� �����I��'q���B��=�1X�
�4���������.����Ϙ���>]C�*>�� �K�9�i2%F=-�O������$_��s���4.���d�JZ���+��N�P7gY��Q6����Q�dи����f��Y�H 3��'�x:�"�<,��Z���G��e33�Ĳ�Лg�+|�6^�U�	����[�ؓ�܂9���dS{cͲ7ǱI�AяUR�WY8'K�jR\y�Z��U.>/km
�7��q��|�-�&�+CW7KI�q�R,{�3��7�WT�p���c}�6���R��6��v���� �'Ȥݑ�X�l�B-��Ɔ4<0Ej�1��h�w��L���4�B"�$�]�C}\"(/#�L ��4�`7I}��OJ@+�
��`��h��}��,%[���qA����j(�O��PR?�O����U`�cp!��>>��^�K�JV�VEX;�����k�{�X�r��f|5'�v<�����M�E�F9�п��}�ڡ��֒�2:�jF1�����kҰ�<���$lncl�i���p�B���#�h���(0��U�@�[P��yY<
���_0���yO�@,����\k
at�H���:�)�7C��C�mlJ�X
R���w7��K�Q�xG��z�kR�9�[`�K�����5�eډ�"ԮK���CC�xq��d��F�{��K|�2Jw\k�~I$Ee	���x�5s�t���p�)[�3�$L������%�$�ZpC�CDb�C��R	e}�DᏑ�2� yP���2�`�Iq�,ʮ|���U�(,�*iƦ����+�L)�|��O�����2q�	�tcy���i�i��H9���3����QSD��▣�×LB*��C�93�#��pΐ��O�T�/��-��ԄZ_�<	W>/�5k��Y����l�G�0�%����审�<���=�/�w'Ո�f��J�h&Dd��$��w�ʩ�ۥ.i7>����a����������s�Kw<n�A�d�T������b�]�����e���9ѣʠ��=�"�1�:!X����m�~N��������!�O1,���`�@��ADNƆ��:@��?bkM8�޸J�����/�w�4�?$��*�H�rJQa�s� =��&@�=���\�jh%��1���%v����H��Z�.�ɠ����b�R]��W%���*�'��ҿV��dw�&�=z^�e�{���>{��Q�+��1� �:����&��v"uw)���c��ٲ����rL���9�?�a\��b�]mq����=���ZUIs�)5N :�X��'����q�KD���?gp��E���8�Ky�?c�������Pv#ѷh��?1���섫��S��~ ׹蓨��t#���D��0f��E�
D�QH�B���D��-�ڔ+� �!�lB�+�qeo:_�Ԑ%���IlO"&��T�j|��7��n=��R������`��ʳ-�X�:/=�urQ�q�&��m?���D�>fԕ�]_�~�(C7>*�nO��&~�0ձ�@�]l��-���FN C�}�޿�W:�:�'7	�&Q�a��_���{���$*Y�7�Yo�%oN��
�\���<��>Z^�%0� ��zn�5�|.�]$�A�3��U>�膤D����c�[^A�ێh��#��Y�⓾7u_S ��n��xύ�0�]O�tv�5�t����go��Ky}����F��fU1Me�h�x��򘎢��鮲�S)����V5�D����H�l_��H	���.6�����
����)�+�cg�'�,3ޔ��=P\�Ysc�� �V���f��	8���jTwR�sy��h��^��異�*R�!���3�c��O������F*�K��8�۳��ź��w�1���}�B� �s�����O��}2�:�4��f�K����h������;�"�p.�y�v����c5?�WM�@��i�弞���*[z�R�?m�Bҋ*	4�[˫.n1���>���	�A�8�؟$я����K1S_�����锄��B�$���"��ń! m������C	��=�JǇs�N/�� ib�(�4��ͨZ�m�.�r���K|aC\���T=]Yh/�.G-7��bQ���>�@&�����[A�cbB@V���
>��K�y�>j�P�D�?�YH��z��G��~\�Kq��J���f�<F�z�ބhl�!��k��d���G��*�>^�~�m_@�Iq���γ�������=�6���ܣo�bZ|��v�\�i��F�*���tjK��7�"Eh��)M-ϒe�]59gF)%1]l(�]Em�� \@6��U�#�mⱦ>�}L_�cƙ�K0U�����~��p#R.��ꭚh�����3��2��n�	m�E�m�Qbwddq��=�a�K�b�x~$Ӓ	���5��ek�bQ~ɯ�Ws�� �)    _ �Ŀ��J��.'J��u��((�1��,`�L9�ľQ)�(�w�hc��4i�u]��>��ڡ��}>=	�{X2��������~�[���_���R2���Չ��-�s�����J/Ҷ&UkU]0�>�"��O%�Y��O�,�!��)x���e�G��I��o��*/��9��~Ǚ�	�-a}�L��ѓW��E�^�}p;h�]�	�4.�Z���)�4�qY��t>I�[���=��` ���G}m��F<�"UH�EPrh������5ӖG�xi��r�c� ��R/�#�Z>��uP\Hz�oL,����(B%��bs�}�"��]�v<��7K� ��N ˠl������J)���~Nv=!#\��	J�4�K�K��\�~+���:X�F�Hˤ/�R��2NQ�Y�luD��.��{����M�1p�3���-���Qx�5P�&8���z���_�LU<�f)?�u�v}o�cP��Ed�1S�>�jb?�d�k�����C���/?0�X��=]싁^�����_�$hʇ>�^��g[�P?�i6�ti����(�)��Y
q�N{���4��RK��%!Waz3:l��EH^�~|W�|�[,�Ԥ�l�1�.���B���[�'����a�3�/������sadܒH�֑.����
�Q������W����`H��L��<[ؕ/���Sdf������%���T� �$��i�!D�-Ӧ_��[eo%4�i?��Pk�l�}r��0�������y���C=�+�ZL�M�"\]�L����9z�匥b���P��}��R&8�'Ԅ?�-�)�E˾ �.���~��{�0�I�_m�	}0�vsI���l��|�����!0��` ����%�gG�¬5�CU+%&��gM��US������2�bi�63��pHE��*���r8�h���<�.�i��l�I�h�}�/B�G
0I��D4�@Ŧ]�K��!Bxѽ�9H�/�*t��ا9���%��[�l�^�s�H��rs��W�w6tc�n�W�(51H�Iy�(b�!���
1�dK��)痢F�e@���mQB�$#�����G�1K�0J�x�zf�.5@�K�ҫ]��jj���j����g�[L���W��l|�D��޺�������f�Lt�f��nI������X���ۧ�^-��z#������x"|g�B d��/���I���k�z��(�Ǽ��a��;T�.�r�gl�a"�o���a
.?���^{>�/���/R�ȎX�EFD&J��Ie#�K���T&����K�y����.��-\��еM1Z`�'�E��k\W�r��Mo��9~jAذ�Jp�kh�@�>7�"R�9zUdl]�2n�ʵ��h8 ���mo�41`���T��Q>gt�Zj�\����&H���ݐo�
��y�3�t�#0���8�}qIo�`M�V�b%d�=B�F( A�B�`���W.�v�or�X&�>��� ��#!��`�,����"�w��&�>���YӰ�+%�]4�����u�����Қߜ~��l�\�X����[H����e_D���%d�Pz�A���/�S�C����K�yX	�z-���5�o���5|/S.nS|���V>�p�q�L%d�"/���9F���Ϭ�0�e� ��Q���C�	$h2,Y3ާ��~��g�_��}���{`T�g��
*�	��3آ����Q�B,A�������peڞ���X�Q2��ӈ�0z�s@R���Nn*��K) �r����j(�&�eE��C�L�?��P4"3���l_2�]Tջ��Gh�z�Q Fj����x��
XO�qO�q���(��ȫ7.������$��y��#�8V��!%�ՠ y+�#�w3J[��FJ�/�ʵ�jwd�[��DM	�ݡ���
SJT��{ؾ�MM�(Yŝ����5�d�dȮ}�p�"�5& �\��ŗ����h�F��/�L��]6�7���s�I�01���/g�o��:�:�\��d.7<���9W�%��<h\n�f�l���kF)�>��G�����q��Y�5A����*WxB-t,�˻���'t$���w 3�u�;���~H����ًT�K�t�*'3�i���&�a��ڸWV$ŷ�T~=�eC�$"i�졇)�OI������I8f�!⢛4�痴7����ޛ�['a�����e�׾@���Aw�ƃ�� R�Օ�+�ˆ��W8,�<=�́>`�Puw��*^0�G�%��,'?�'C�+��}��htuLb-�y��7w������<��a1��f&��g� �L�s�Y�8<�P���������+ LhB���3q{܅ۯ���7"����x�
yk/�(W�<���3/^�a�O�����qg����XJB�����Ҵ:�$��~:A��t�u��i9#���𧕊8D�?'�B<�)��ސ�ԥJ��`��"v#��U�)�w/4O��d����{�cQ���&�A*�q�<�F��"U
H*��"�P� �H�)»��\ST����L����0|�1�Q�緡"�c����[�`;��v� �F@�~u}#XPd7��c�I��ˮ�+�҆��j"���_%?�� �45�M�[]���M�Gñ�����(�ӘaSft��SQ)Y��A��j���=����K뷗��{����+溏�i�.e����B��g�{C��aj`{��y���HQcفP�ř	��ʷDidܱ�ja�����#E �@�z2#�k'p���$�V[�d!��&��i@�u������Iȃ�OP�v����k$��� 닜���t��w�6����]�u�ּG!FkU�Vؙ�w��>�g�n��^����l9oY���Z�K��&���1�A��輍�ǫ�v/ڀe�"����_�uw�3j)�@��|gWO.���eOʛV_s�@���\ 1���*?�
T�9����qoJ�W�z�s:Nן�=4uI���X�h�^&vd��w�! Y��7�Q��E�p�V����.+&{�w��_������nwv��i"%�s���4�c�����⨓��SHB]Uu�h�g�CҊWB�]��ǭA�*�Z�߂�����g�Os�5]E���f-fT�v�U��ml�ia��Yۺ������������|���U$G�d�S���GZ�.���wǀ�Z&�q������ĳ��~��ia�W:i�ZNU-�^Ik���6�Z(4�A�%�#��X���>�B�~�o��I��+�8��ǧ8��_'G�Yq���o�?ݾf��y�~��4��Y,�ݏN��BBa�
У�
�j4�'x_����tO F=�we�ˁ*bX1�ڢG˽=]��)�{k_���ӴYm��`M��7 ��ƕ���Y\��i�n�z��.��~�p���r���T�Y�J�I�ޢ�����<����ݸDfǸVsӆv^N�Z8� y��8�I��?�
��]`ެWN�uy�m�4D��7Efx����P:�x�L�������(��vh��:{ƻp�P|7$o'O	z�~����`��V͏1�\�k�0?��+5	~�Κ<����cMg��S��m���6��&v/�f*j��wc=*��JoL�q�m֢+�@
�n�U<��4
����������}�c1k]qmT��KT1�]�n�.���}����@���]h���=1y��q�KMp�H���`�3$�9)x�z��@����u�v��6=�k�	���t�����Y4��&7��W�p��ݽ�>!%g�����g.�Ϟ�7�^4l����Ff�̤۔}�W���,�H�g�.f����0��~%��6w�hsҼ�v\�U��H@�i������Հ�m��-�� �����6���@�\
��-�v���A�T0�j��
�P��i�.�O4h-6��	���~I�pn$wR�r�S8�֛ZQO J�:��BJ��=�K�[`	����e���kV������aN�NJ�:���J�|�s�iR� )   jp*�V�*���d��J�߲Dq0�ϛZ�����o����L         p   x�3��������N,�OI����##��������\N �D��T��B��������R�����Ĉ��ˈӥ47��3�8��3�"1� '�^C+#3=3#�n�4�=... ޺%     