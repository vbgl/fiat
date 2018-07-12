Require Import
        Coq.Strings.String
        Coq.Vectors.Vector.

Require Import
        Fiat.Common.SumType
        Fiat.Common.EnumType
        Fiat.Common.BoundedLookup
        Fiat.Common.ilist
        Fiat.Computation
        Fiat.QueryStructure.Specification.Representation.Notations
        Fiat.QueryStructure.Specification.Representation.Heading
        Fiat.QueryStructure.Specification.Representation.Tuple
        Fiat.Narcissus.BinLib.Core
        Fiat.Narcissus.Common.Specs
        Fiat.Narcissus.Common.WordFacts
        Fiat.Narcissus.Common.ComposeCheckSum
        Fiat.Narcissus.Common.ComposeIf
        Fiat.Narcissus.Common.ComposeOpt
        Fiat.Narcissus.Automation.SolverOpt
        Fiat.Narcissus.Formats.FixListOpt
        Fiat.Narcissus.Stores.EmptyStore
        Fiat.Narcissus.Formats.WordOpt
        Fiat.Narcissus.Formats.Bool
        Fiat.Narcissus.Formats.NatOpt
        Fiat.Narcissus.Formats.Vector
        Fiat.Narcissus.Formats.EnumOpt
        Fiat.Narcissus.Formats.SumTypeOpt
        Fiat.Narcissus.Formats.IPChecksum.

Require Import Bedrock.Word.

Import Vectors.VectorDef.VectorNotations.
Require Import
        Fiat.Narcissus.BinLib.AlignedDecodeMonad
        Fiat.Narcissus.BinLib.AlignedEncodeMonad.

Open Scope string_scope.
Open Scope Tuple_scope.

Definition InjectEnum {n A}
           (gallina_constructors: VectorDef.t A n)
           (enum_member: Fin.t n) : A :=
  VectorDef.nth gallina_constructors enum_member.

Definition MakeDecoder {A B} sz
           (impl: forall {sz}, Vector.t char sz -> option (A * nat * B))
           (bs: Vector.t char sz) : option A :=
  match impl bs with
  | Some (pkt, _, _) => Some (pkt)
  | None => None
  end.

Definition MakeEncoder {A B} sz
           (impl: forall {sz}, Vector.t char sz -> A -> option (Vector.t char sz * nat * B))
           (pkt: A) (out: Vector.t char sz) : option (Vector.t char sz) :=
  match impl out pkt with
  | Some (out, _, _) => Some out
  | None => None
  end.

Require Import Fiat.Narcissus.Examples.NetworkStack.EthernetHeader.

Section Ethernet.
  Inductive fiat_ethernet_type := ARP | IP | IPV6 | RARP.

  Definition fiat_ethernet_type_of_enum (enum: EnumType ["ARP"; "IP"; "IPV6"; "RARP"]) : fiat_ethernet_type :=
    InjectEnum [ARP; IP; IPV6; RARP] enum.

  Definition fiat_ethernet_type_to_enum (type: fiat_ethernet_type) : EnumType ["ARP"; "IP"; "IPV6"; "RARP"] :=
    match type with
    | ARP => ```"ARP"
    | IP => ```"IP"
    | IPV6 => ```"IPV6"
    | RARP => ```"RARP"
    end.

  Definition fiat_ethernet_encode {sz} :=
    MakeEncoder sz (fun sz v pkt => @EthernetHeader_encoder_impl pkt sz v).
  Definition fiat_ethernet_decode {sz} v packet_length :=
    MakeDecoder sz (@Ethernet_decoder_impl packet_length) v.
End Ethernet.

Require Import Fiat.Narcissus.Examples.NetworkStack.ARPPacket.

Section ARP.
  Inductive fiat_arp_hardtype := Ethernet | IEEE802 | Chaos.
  Definition fiat_arp_hardtype_of_enum (enum: EnumType ["Ethernet"; "IEEE802"; "Chaos"]) :=
    InjectEnum [Ethernet; IEEE802; Chaos] enum.
  Definition fiat_arp_hardtype_to_enum (hardtype: fiat_arp_hardtype)
    : EnumType ["Ethernet"; "IEEE802"; "Chaos"] :=
    match hardtype with
    | Ethernet => ```"Ethernet"
    | IEEE802 => ```"IEEE802"
    | Chaos => ```"Chaos"
    end.

  Inductive fiat_arp_prottype := IPv4 | IPv6.
  Definition fiat_arp_prottype_of_enum (enum: EnumType ["IPv4"; "IPv6"]) :=
    InjectEnum [IPv4; IPv6] enum.
  Definition fiat_arp_prottype_to_enum (prottype: fiat_arp_prottype)
    : EnumType ["IPv4"; "IPv6"] :=
    match prottype with
    | IPv4 => ```"IPv4"
    | IPv6 => ```"IPv6"
    end.

  Inductive fiat_arp_operation := Request | Reply | RARPRequest | RARPReply.
  Definition fiat_arp_operation_of_enum (enum: EnumType ["Request"; "Reply"; "RARPRequest"; "RARPReply"]) :=
    InjectEnum [Request; Reply; RARPRequest; RARPReply] enum.
  Definition fiat_arp_operation_to_enum (operation: fiat_arp_operation)
    : EnumType ["Request"; "Reply"; "RARPRequest"; "RARPReply"] :=
    match operation with
    | Request => ```"Request"
    | Reply => ```"Reply"
    | RARPRequest => ```"RARPRequest"
    | RARPReply => ```"RARPReply"
    end.

  Definition fiat_arp_decode {sz} :=
    MakeDecoder sz (@ARP_decoder_impl).
  Definition fiat_arp_encode {sz} :=
    MakeEncoder sz (@ARP_encoder_impl).
End ARP.

Require Import Fiat.Narcissus.Examples.NetworkStack.IPv4Header.

Section IPv4.
  Inductive fiat_ipv4_protocol :=
  | ICMP | TCP | UDP.
  Definition fiat_ipv4_protocol_of_enum (proto: EnumType ["ICMP"; "TCP"; "UDP"]) : fiat_ipv4_protocol :=
    InjectEnum [ICMP; TCP; UDP] proto.
  Definition fiat_ipv4_protocol_to_enum (proto: fiat_ipv4_protocol)
    : EnumType ["ICMP"; "TCP"; "UDP"] :=
    match proto with
    | ICMP => ```"ICMP"
    | TCP => ```"TCP"
    | UDP => ```"UDP"
    end.

  Definition fiat_ipv4_decode {sz} :=
    MakeDecoder sz (@IPv4_decoder_impl).
  Definition fiat_ipv4_encode {sz} :=
    MakeEncoder sz (@IPv4_encoder_impl).
End IPv4.

Require Import Fiat.Narcissus.Examples.NetworkStack.TCP_Packet.
Section TCP.
  Definition fiat_tcp_encode {sz} v srcAddress dstAddress tcpLength :=
    MakeEncoder sz (fun sz v pkt => @TCP_encoder_impl srcAddress dstAddress tcpLength pkt sz v) v.
  Definition fiat_tcp_decode {sz} v (srcAddress dstAddress: Vector.t (word 8) 4) tcpLength :=
    MakeDecoder sz (@TCP_decoder_impl srcAddress dstAddress tcpLength) v.
End TCP.

Require Import UDP_Packet.
Section UDP.
  Definition fiat_udp_encode {sz} v srcAddress dstAddress udpLength :=
    MakeEncoder sz (fun sz v pkt => @UDP_encoder_impl srcAddress dstAddress udpLength pkt sz v) v.
  Definition fiat_udp_decode {sz} v (srcAddress dstAddress: Vector.t (word 8) 4) (udpLength: word 16) :=
    MakeDecoder sz (@UDP_decoder_impl srcAddress dstAddress udpLength) v.
End UDP.

Require Import ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlString.

(* Work around the fact that Decimal declares a type "int" *)
Extract Inductive nat => "OCamlNativeInt.t" [ "0" "Pervasives.succ" ]
 "(fun fO fS n -> if n=0 then fO () else fS (n-1))".

Extract Inductive prod => "(*)"  [ "(,)" ].
Extract Inlined Constant NPeano.ltb => "(<)".
Extract Inlined Constant NPeano.leb => "(<=)".

(** * Inline a few functions *)
Extraction Inline If_Opt_Then_Else.
Extraction Inline fst snd Basics.compose.
Extraction Inline BindAlignedDecodeM ReturnAlignedDecodeM ThrowAlignedDecodeM.
Extraction Inline AppendAlignedEncodeM ReturnAlignedEncodeM ThrowAlignedEncodeM.
(* Extraction Inline decode_nat decode_word decode_word'. *)

(** * Extract words as int64
      (Only works for words with length < 64) *)

Extract Inductive Word.word =>
"Int64Word.t"
  ["(Int64Word.w0)" "Int64Word.ws"]
  "Int64Word.destruct".

Extract Inlined Constant whd => "Int64Word.whd".
Extract Inlined Constant wtl => "Int64Word.wtl".
Extract Inlined Constant zext => "Int64Word.zext".
Extract Inlined Constant wplus => "Int64Word.wplus".
Extract Inlined Constant wmult => "Int64Word.wmult".
Extract Inlined Constant wminus => "Int64Word.wminus".
Extract Inlined Constant weq => "Int64Word.weq".
Extract Inlined Constant weqb => "Int64Word.weqb".
Extract Inlined Constant wlt => "Int64Word.wlt".
Extract Inlined Constant wlt_dec => "Int64Word.wlt_dec".
Extract Inlined Constant wand => "Int64Word.wand".
Extract Inlined Constant wor => "Int64Word.wor".
Extract Inlined Constant wnot => "Int64Word.wnot".
Extract Inlined Constant wneg => "Int64Word.wneg".
Extract Inlined Constant wordToNat => "Int64Word.wordToNat".
Extract Inlined Constant natToWord => "Int64Word.natToWord".
Extract Inlined Constant wzero => "Int64Word.wzero".
Extract Inlined Constant wzero' => "Int64Word.wzero'".
Extract Inlined Constant wones => "Int64Word.wones".

Extract Inlined Constant word_split_hd => "Int64Word.word_split_hd".
Extract Inlined Constant word_split_tl => "Int64Word.word_split_tl".
Extract Inlined Constant AlignWord.split1' => "Int64Word.split1'".
Extract Inlined Constant AlignWord.split2' => "Int64Word.split2'".
Extract Inlined Constant split1 => "Int64Word.split1".
Extract Inlined Constant split2 => "Int64Word.split2".
Extract Inlined Constant SW_word => "Int64Word.SW_word".
Extract Inlined Constant combine => "Int64Word.combine".
Extract Inlined Constant append_word => "Int64Word.append".

Definition word_split_hd_test := word_split_hd (natToWord 5 30).
Definition word_split_tl_test := wordToNat (word_split_tl (natToWord 5 30)).
Definition alignword_split1'_test := wordToNat (AlignWord.split1' 2 3 (natToWord 5 30)).
Definition alignword_split2'_test := wordToNat (AlignWord.split2' 2 3 (natToWord 5 30)).
Definition split1_test := wordToNat (split1 3 2 (natToWord 5 30)).
Definition split2_test := wordToNat (split2 3 2 (natToWord 5 30)).
Definition combine_test := wordToNat (combine (natToWord 5 30) (natToWord 7 14)).
Definition append_word_test := wordToNat (append_word (@natToWord 8 5) (@natToWord 12 126)).

(** * Special case of internet checksum *)
Extract Constant InternetChecksum.OneC_plus => "Int64Word.onec_plus".

(** Efficient bytestrings *)

Extract Inductive Fin.t =>
"ArrayVector.idx_t"
  ["ArrayVector.zero" "ArrayVector.succ"]
  "ArrayVector.destruct_idx".

Extract Inlined Constant Fin.L => "(fun _ n p -> p)".
Extract Inlined Constant Fin.R => "(fun _ n p -> n + p)".

Extract Inductive Vector.t =>
"ArrayVector.storage_t"
  ["ArrayVector.empty ()" "ArrayVector.cons"]
  "ArrayVector.destruct_storage".
Extract Inductive VectorDef.t =>
"ArrayVector.storage_t"
  ["ArrayVector.empty ()" "ArrayVector.cons"]
  "ArrayVector.destruct_storage".

Extract Inlined Constant Vector.hd => "ArrayVector.hd".
Extract Inlined Constant VectorDef.hd => "ArrayVector.hd".
Extract Inlined Constant Vector.tl => "ArrayVector.tl".
Extract Inlined Constant VectorDef.tl => "ArrayVector.tl".
Extract Inlined Constant Vector.to_list => "ArrayVector.to_list".
Extract Inlined Constant VectorDef.to_list => "ArrayVector.to_list".
Extract Inlined Constant Vector.append => "ArrayVector.append".
Extract Inlined Constant VectorDef.append => "ArrayVector.append".
Extract Inlined Constant Vector.nth => "ArrayVector.nth".
Extract Inlined Constant VectorDef.nth => "ArrayVector.nth".
Extract Inlined Constant nth_opt => "ArrayVector.nth_opt".
Extract Inlined Constant set_nth' => "ArrayVector.set_nth".
Extract Inlined Constant word_indexed => "ArrayVector.index".
Extract Inlined Constant InternetChecksum.Vector_fold_left_pair => "ArrayVector.fold_left_pair".

Definition mirage_pkt : Vector.t (word 8) _ :=
  Eval compute in Vector.map (@natToWord 8)
                             [69; 184; 0; 76; 191; 124; 64; 0; 52; 17; 223; 101; 144; 92; 9; 22; 10; 137; 3; 12; 0; 123; 0; 123; 0; 56; 244; 251; 36; 1; 3; 238; 0; 0; 0; 0; 0; 0; 0; 67; 71; 80; 83; 0; 220; 3; 208; 4; 83; 118; 115; 149; 220; 3; 208; 6; 203; 210; 79; 251; 220; 3; 208; 6; 205; 87; 67; 160; 220; 3; 208; 6; 205; 182; 46; 81].

Require Import NArith.

Compute
  match IPv4_decoder_impl bin_pkt with
  | Some (p, _, _) =>
    match IPv4_encoder_impl (AlignedByteString.initialize_Aligned_ByteString 20) p with
    | Some (bytes, _, _) => Some (Vector.map (@wordToNat 8) bytes)
    | None => None
    end
  | None => None
  end.

Definition fiat_ipv4_decode_bench (_: unit) :=
  fiat_ipv4_decode bin_pkt.
Definition fiat_ipv4_encode_bench (_: unit) :=
  fiat_ipv4_encode IPv4Header.pkt (AlignedByteString.initialize_Aligned_ByteString 20).

(* Definition fiat_ipv4_decode_test := fiat_ipv4_decode_bench (). *)
(* Definition fiat_ipv4_decode_reference := Eval compute in fiat_ipv4_decode_test. *)

(* Definition fiat_ipv4_encode_test := fiat_ipv4_encode_bench (). *)
(* Definition fiat_ipv4_encode_reference := Eval compute in fiat_ipv4_encode_test. *)

(* Definition should_fail := *)
(*   let bs := (AlignedByteString.initialize_Aligned_ByteString 20) in *)
(*   let bs' := set_nth' bs 10 (wone _) in *)
(*   let bs'' := set_nth' bs 10 (wone _) in *)
(*   (bs', bs''). *)

(* Definition src : Vector.t (word 8) _ := *)
(*   Eval compute in Vector.map (@natToWord 8) [10; 1; 168; 0]. *)

(* Definition dst : Vector.t (word 8) _ := *)
(*   Eval compute in Vector.map (@natToWord 8) [10; 1; 168; 0]. *)

(* Definition pkt : Vector.t (word 8) _ := *)
(*   Eval compute in Vector.map (@natToWord 8) [65; 155; 0; 7; 27; 205; 13; 135; 0; 0; 0; 0; 112; 2; 22; 208; 125; 0; 0; 0; 2; 4; 5; 180; 3; 3; 2; 0]. *)

(* Definition len : word 16 := natToWord 16 28. *)

(* Compute (fiat_tcp_decode pkt src dst len). *)

(* Extraction "debug" test.  *)

(* Definition pkt : Vector.t (word 8) _ := *)
(*   Eval compute in Vector.map (@natToWord 8) [51; 51; 255; 0; 0; 69; 2; 80; 0; 0; 0; 1; 134; 221; 96; 0; 0; 0; 0; 32; 58; 255; 252; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 35; 255; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 255; 0; 0; 69; 135; 0; 126; 159; 0; 0; 0; 0; 252; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 69; 1; 1; 2; 80; 0; 0; 0; 1]. *)

(* Definition test := fiat_ethernet_decode pkt 86. *)

(* Extraction "debug" test. *)

Extraction "Fiat4Mirage"
           (* word_split_hd_test *)
           (* word_split_tl_test *)
           (* split1_test *)
           (* split2_test *)
           (* alignword_split1'_test *)
           (* alignword_split2'_test *)
           (* combine_test *)
           (* append_word_test *)

           fiat_ipv4_decode_bench
           (* fiat_ipv4_decode_test *)
           (* fiat_ipv4_decode_reference *)
           fiat_ipv4_encode_bench
           (* fiat_ipv4_encode_test *)

           fiat_ethernet_type_of_enum
           fiat_ethernet_type_to_enum
           fiat_ethernet_encode
           fiat_ethernet_decode
           fiat_arp_hardtype_of_enum
           fiat_arp_hardtype_to_enum
           fiat_arp_prottype_of_enum
           fiat_arp_prottype_to_enum
           fiat_arp_operation_of_enum
           fiat_arp_operation_to_enum
           fiat_arp_decode
           fiat_arp_encode
           fiat_ipv4_protocol_of_enum
           fiat_ipv4_protocol_to_enum
           fiat_ipv4_decode
           fiat_ipv4_encode
           fiat_tcp_encode
           fiat_tcp_decode
           fiat_udp_encode
           fiat_udp_decode
.

Definition payload := Vector.to_list (Vector.map (natToWord 8) [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0]).

Definition out := Vector.map (natToWord 8) [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0].

Compute (fiat_udp_encode
           {| SourcePort := natToWord _ 1;
              DestPort := natToWord _ 2;
              Payload := payload |}
           (Vector.map (natToWord 8) [127; 0; 0; 1])
           (Vector.map (natToWord 8) [127; 0; 0; 1])
           (natToWord 16 108)
           out).

(* Definition http_request_tcp_decode_input := *)
(*   Vector.map (natToWord 8) [151; 156; 0; 80; 35; 228; 55; 62; 203; 6; 21; 82; 128; 24; 0; 229; 174; 223; 0; 0; 1; 1; 8; 10; 43; 241; 57; 249; 5; 65; 240; 70; 71; 69; 84; 32; 47; 32; 72; 84; 84; 80; 47; 49; 46; 49; 13; 10; 72; 111; 115; 116; 58; 32; 101; 120; 97; 109; 112; 108; 101; 46; 99; 111; 109; 13; 10; 85; 115; 101; 114; 45; 65; 103; 101; 110; 116; 58; 32; 99; 117; 114; 108; 47; 55; 46; 52; 55; 46; 48; 13; 10; 65; 99; 99; 101; 112; 116; 58; 32; 42; 47; 42; 13; 10; 13; 10]. *)

(* Definition srcAddr := (Vector.map (natToWord 8) [192; 168; 1; 109]). *)
(* Definition destAddr := (Vector.map (natToWord 8) [93; 184; 216; 34]). *)

(* Compute (@TCP_decoder_impl srcAddr destAddr (natToWord 16 107) _ http_request_tcp_decode_input). *)

(* Definition simple_udp : Vector.t (word 8) _ := *)
(*   Eval compute in Vector.map (@natToWord 8) [134; 62; 0; 53; 0; 8; 245; 171]. *)

(* Definition srcAddr := Vector.map (@natToWord 8) [192;168;1;109]. *)
(* Definition destAddr := Vector.map (@natToWord 8) [192;168;1;1]. *)
(* Definition udpLength := natToWord 16 8. *)

(* Compute (@UDP_decoder_impl srcAddr destAddr (natToWord 16 8) _ simple_udp). *)

(* Compute (AlignedIPChecksum.Vector_checksum_bound' *)
(*            (12 + sz) *)
(*            (srcAddr ++ destAddr ++ wzero 8 :: natToWord 8 17 :: split2 8 8 udpLength :: split1 8 8 udpLength :: v)%vector) *)

(* (*  *)
(*    Issues:  *)
(*    - length is in wrong order, so computation fails *)
(*  *) *)

(* Compute (Vector.map (@wordToNat 8) (srcAddr ++ destAddr ++ [wzero 8; natToWord 8 17] ++ udpLength ++ simple_udp)%vector). *)

(* Locate "_ ++ _". *)
(* Compute (AlignedIPChecksum.Vector_checksum_bound' *)
(*            (12 + 8) *)
(*            (srcAddr ++ dstAddr ++ [wzero 8; protoCode] ++ udpLength ++ v)%vector). *)

Set Printing Depth 1000.
Print TCP_decoder_impl.
Print GetCurrentByte.
Print AlignedList.ListAlignedDecodeM.