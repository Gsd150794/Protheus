#Include "TOTVS.ch"
#Include "RwMake.ch"
#Include "TopConn.CH"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ OM200GRV º Autor ³ Wodson Reis Silva     º Data da Criacao  ³ 03/08/2009                						º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Ponto de Entrada apos a gravacao dos campos principais do arquivo de pedidos na montagem de carga, que       º±±
±±º          ³ permite ao usuario gravar seus campos especificos.                                                           º±±
±±º          ³ Os campos especificos devem ser incluidos no array no ponto de entrada DL200TRB.                             º±±
±±º		     ³					 												                                            º±±
±±º		     ³ Caso seja necessario adicionar mais campos a serem apresentados no Grid, proceda da seguinte forma:          º±±
±±º		     ³ 1 - Campo do SC5, basta informa-lo no parametro IT_CMPCARG.                                                  º±±
±±º		     ³ 2 - Campo de outra tabela, por exemplo SC6, informe o campo no parametro para que nao seja necessario editar º±±
±±º		     ³     os pontos de entrada DL200BRW e DL200TRB.                                                                º±±
±±º		     ³     Em seguida, no P.E OMS200GRV faca um If no Laco para desconsiderar algum campo que se inicie             º±±
±±º		     ³                                                                                                              º±±
±±º		     ³                                                                                                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Gravacao e apresentacao de campos de usuario na Grid da tela de Montagem de Carga.	                        º±±
±±º		     ³					 												                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ Alias da tabela para atualizacao.                                                       						º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ Nenhum.                                                           	                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUsuario   ³                                                                                          					º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºSetor     ³ Logistica                                                                               						º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          |
------------------:------------:----------------------------------------------------------------------------------------------:
 Alex Wallauer    | 26/12/2016 | Ajustes da Unificação - Pre-Carga - Chamado 18245                                            |
===============================================================================================================================
/*/
User Function OM200GRV()

Local aArea    := FWGetArea()
Local aAreaPED := TRBPED->(GetArea())
Local aAreaSC5 := SC5->(GetArea())
Local aCpos    := {} //{"C5_I_EST  ","C5_I_CMUN ","C5_I_GRPVE","C5_I_OBPED","C5_VEND1  ","C5_VEND2  ","A1_NATUREZ","C6_I_QPALT","C6_PEDCLI ","C6_ENTREG "}
Local nX       := 0

If TRBPED->(Eof()) .And. TRBPED->(Bof())
   Return 
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Arrays de controle dos campos que deverao ser mostrados no Grid da rotina de Montagem de Carga.   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCpos := AllTrim(GetMv("IT_CMPCARG"))
aCpos := If(Empty(aCpos),{},&aCpos)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Gravacao automatica dos campos informados no parametro IT_CMPCARG.   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RecLock("TRBPED",.F.)
For nX := 1 To Len(aCpos)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o campo vem da tabela SC5, caso contrario a gravacao tem que ser fora do laco. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SubStr(aCpos[nX],1,2) == "C5"
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Tratamento para que o nome do campo nao exceda 10 digitos. ³
		//³ Caso exceda, trunca a ultima posicao.                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Len("PED"+SubStr(aCpos[nX],3,Len(AllTrim(aCpos[nX]))-2)) > 10
			TRBPED->&("PED"+SubStr(aCpos[nX],3,7)) := SC5->&("C5"+SubStr(aCpos[nX],3,Len(AllTrim(aCpos[nX]))-2))
		Else
			TRBPED->&("PED"+SubStr(aCpos[nX],3,Len(AllTrim(aCpos[nX]))-2)) := SC5->&("C5"+SubStr(aCpos[nX],3,Len(AllTrim(aCpos[nX]))-2))
		EndIf
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Coloque aqui a gravacao dos campos que nao sao do SC5.                                  ³
		//³ Obs:                                                                                    ³
		//³      O nome do campo no arquivo de trabalho nao pode exceder 10 caracteres,             ³
		//³      logo o mesmo sera truncado nas ultimas posicoes para evitar erro, por exemplo:     ³
		//³      - O campo C6_PRODUTO, ficaria no arquivo de trabalho PED_PRODUT.                   ³
		//³      - O campo C6_I_QPALT, ficaria no arquivo de trabalho PED_I_QPAL.                   ³
		//³                                                                                         ³
		//³ Dica:                                                                                   ³
		//³      Cuidado para algum campo que tenha mais de 10 digitos, nao truncar e ficar com     ³
		//³      nome igual ao de outro, por exemplo C6_QTDEMP ficaria PED_QTDEMP e o C6_QTDEMP2    ³
		//³      tambem ficaria PED_QTDEMP. Nesse caso vc nao pode informar o campo no parametro    ³
		//³      IT_CMPCARG, tera que editar os P.E DL200BRW,DL200TRB e OM200GRV manualmente.       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		/*
		TRBPED->PED_ENTREG := SC6->C6_ENTREG
		TRBPED->PED_PEDCLI := SC6->C6_PEDCLI
		TRBPED->PED_I_QPAL := SC6->C6_I_QPALT
		TRBPED->PED_NATURE := SA1->A1_NATUREZ
		*/
	EndIf
Next nX
MSUnLock()

FWRestArea(aArea)
FWRestArea(aAreaSC5)
FWRestArea(aAreaPED)

Return
