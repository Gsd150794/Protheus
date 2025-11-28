/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/11/2019| Chamado 28346. Revisão de fonte para novo appserver
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA105OK
Autor-------------: André Lisboa
Data da Criacao---: 18/06/2014 
Descrição---------: Ponto de Entrada que valida estorno de produção / Chamado apos confirmação de estorno de produções. 
                    Este ponto de entrada permite validar algum campo especifico do usuario antes de se realizar o Estorno.
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar estorno / .F. = Nao Permite confirmar estorno   
===============================================================================================================================
*/
User Function MT250EST()
Local XX   
   
   L_RET:=.T.
   N_AREAEST:=SELECT()
   
   DBSelectArea("SB2")
   N_ORDB2:=INDEXORD()
   N_REGB2:=Recno()
   
   DBSeek(xFilial("SB2")+SD3->(D3_COD+D3_LOCAL))
   N_SALDODSP:=SALDOSB2()
   N_SLDACLA :=SB2->B2_QACLASS
   
   If dDATABASE<SD3->D3_EMISSAO
      U_ITMsg("A data base não pode ser anterior a data do movimento a estornar.","Atenção",;
			  "Favor ajustar a data do sistema para a data do estorno.",1)
      L_RET:=.F.
   EndIf
   
   //VERIFICA SE TEM SALDO NA DATA DO ESTORNO DA PRODUCAO
   If (L_RET) .And.  (GETMV("MV_ESTNEG")<>"S")
   
      nDIASVERIF:=(DATE()-SD3->D3_EMISSAO)+1     //18/06/2014 - 14/05/2014 = 35 + 1 (para englobar tambem o dia atual)
      If nDIASVERIF>0
         dDIAAUX:=SD3->D3_EMISSAO   //dia auxiliar para percorrer dias a verificar
         For XX:=1 TO nDIASVERIF
            aSaldos:=CalcEst(SD3->D3_COD,SD3->D3_LOCAL,dDIAAUX+1)
            nQuant :=aSaldos[1]

            If nQUANT<SD3->D3_QUANT
               U_ITMsg("O lançamento não pode ser estornado pois geraria saldo negativo em: "+DToC(dDIAAUX)+" Saldo disponivel na data: "+AllTrim(TRANSFORM(nQUANT,"@E 999999,999.99")),"Atenção",,1)
               L_RET:=.F.
               Exit
            EndIf 
            dDIAAUX:=dDIAAUX+1
         Next 
      EndIf      
   EndIf   
   
   DBSelectArea("SB2")
   DBSetOrder(N_ORDB2)
   DBGoTo(N_REGB2)
   
   DBSelectArea(N_AREAEST)
   
   //VERIFICA SE TEM APONTAMENTO DE PERDA APONTADO PARA A OP
      
   DBSelectArea("SBC")
   DBSetOrder(1)
   If DBSeek(xFilial("SBC")+SD3->D3_OP)
      U_ITMsg("Não é possível estonar a produção para esta OP, pois existe apontamento de perda lançado para a OP!.","Atenção",;
			  "Exclua os apontamentos de perda para esta OP antes de estornar a produção",1)
      L_RET:=.F.
   EndIf   

Return(L_RET)
