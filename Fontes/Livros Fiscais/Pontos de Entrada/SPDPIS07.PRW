/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |09/08/2018| Chamado 25825. Retirado o retorno das contas genericas
Julio Paz     |13/12/2019| Chamado 31211. Alterar função de obtenção da conta contábil para funcionar de forma genérica.
Alex Wallauer |24/01/2020| Chamado 31770. Colocada a CFOP  6108 como exceção
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: SPDPIS07
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/11/2017
Descrição---------: Ponto de entrada de ajuste de dados no Sped Pis/Cofins - Chamado 21796
Parametros--------: ParamIXB[1]	 	 	Caracter	 	 		FT_FILIAL	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[2]	 	 	Array of Record	 	 	FT_TIPOMOV	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[3]	 	 	Array of Record	 	 	FT_SERIE	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[4]	 	 	Array of Record	 	 	FT_NFISCAL	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[5]	 	 	Array of Record	 	 	FT_CLIEFOR	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[6]	 	 	Array of Record	 	 	FT_LOJA	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[7]	 	 	Array of Record	 	 	FT_ITEM	 	 	 	 	 	 	 	 	 	 
 					ParamIXB[8]	 	 	Array of Record	 	 	FT_PRODUTO	 	 	
Retorno-----------: _cContAju - Código da Conta Contábil Ajustada
===============================================================================================================================
*/
User Function SPDPIS07()

Local _cContAju := " " //Se não tiver regra retorna vazio para não gerar a linha 500

Begin Sequence
   //_cContAju := SPDPIS7C(_cFilial   , _cTipoMov ,  _cSerie  , _cNFiscal , _cClieForn, _cLoja    , _cItem    , _cProduto )
   _cContAju   := U_SPDPIS7C(ParamIXB[1],ParamIXB[2],ParamIXB[3],ParamIXB[4],ParamIXB[5],ParamIXB[6],ParamIXB[7],ParamIXB[8])

End Sequence

Return _cContAju
                        
/*
===============================================================================================================================
Programa----------: SPDPIS7C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/12/2019
Descrição---------: Função generica para retornar o numero da conta contábil, utilizada pelo Ponto de entrada de ajuste de 
                    dados no Sped Pis/Cofins. Rotina transferida da função SPDPIS07 para função SPDPIS7C.
Parametros--------: _cFilial   - Codigo da filial        - ParamIXB[1]  Caracter	 	 FT_FILIAL	 	 	 	 	 	 	 	 	 	 
 					_cTipoMov  - Tipo de movimento       - ParamIXB[2]  Array of Record  FT_TIPOMOV	 	 	 	 	 	 	 	 	 	 
 					_cSerie    - Serie da NF             - ParamIXB[3]  Array of Record  FT_SERIE	 	 	 	 	 	 	 	 	 	 
 					_cNFiscal  - Nr Nota Fiscal          - ParamIXB[4]  Array of Record  FT_NFISCAL	 	 	 	 	 	 	 	 	 	 
 					_cClieForn - Cliente/Fornecedor      - ParamIXB[5]  Array of Record	 FT_CLIEFOR	 	 	 	 	 	 	 	 	 	 
 					_cLoja     - Loja Cliente/Fornecedor - ParamIXB[6] 	Array of Record	 FT_LOJA	 	 	 	 	 	 	 	 	 	 
 					_cItem     - Item da NF              - ParamIXB[7] 	Array of Record	 FT_ITEM	 	 	 	 	 	 	 	 	 	 
 					_cProduto  - Codigo do Produto       - ParamIXB[8] 	Array of Record	 FT_PRODUTO	 	 	
Retorno-----------: _cContAju  - Código da Conta Contábil Ajustada, com base nas regras estabelecidas.
===============================================================================================================================
*/                //      1          2          3        4          5          6      7        8
User Function SPDPIS7C(_cFilial, _cTipoMov, _cSerie, _cNFiscal, _cClieForn, _cLoja, _cItem, _cProduto)
Local _cContAju := " " //Se não tiver regra retorna vazio para não gerar a linha 500
Local _aareaSB1 := SB1->(GetArea())
Local _aareaSFT := SFT->(GetArea())
Local _cAlias   := Getnextalias()

Begin Sequence

   SB1->(DBSetOrder(1))
   SFT->(DBSetOrder(1)) //FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO

   If SB1->(DBSeek(xFilial("SB1")+AllTrim(_cProduto))) .And. SFT->(DBSeek(_cFilial+_cTipoMov+_cSerie+_cNFiscal+_cClieForn+_cLoja+_cItem +_cProduto))

	  //Busca regras
	  _cQuery := " SELECT R_E_C_N_O_ REC_ZGH "
	  _cQuery += " FROM "+ RetSqlName("ZGH") +" ZGH "
	  _cQuery += " WHERE ZGH.ZGH_FILIAL = '"+ AllTrim(SFT->FT_FILIAL)  +"' "
      _lEhClente:=.F.
      //A regras sempre estarão com os CFOP de 1000 a 1999 e de 5000 a 5999
      _xCFOP:=Val(SFT->FT_CFOP)
      If (_xCFOP >= 2000 .And. _xCFOP < 4000) 
         _xCFOP:="1"+SubStr(SFT->FT_CFOP,2)
      ElseIf (_xCFOP >= 6000 .And. _xCFOP < 8000) .And. _xCFOP <> 6108
         _xCFOP:="5"+SubStr(SFT->FT_CFOP,2)
      Else
         _xCFOP:=SFT->FT_CFOP
      EndIf   

      If !Empty(SFT->FT_CLIENT)// Se preenchido é Cliente 
	     _cQuery += " AND	( (ZGH.ZGH_CLIENT = '"+ AllTrim(SFT->FT_CLIEFOR) +"' ) OR (ZGH.ZGH_FORNER = '  ' AND ZGH.ZGH_CLIENT = '  ') ) "//AND ZGH.ZGH_CLILOJ = '"+ AllTrim(SFT->FT_LOJA) +"'
         _lEhClente:=.T.
      Else //  Se em branco é fornecedor
	     _cQuery += " AND	( (ZGH.ZGH_FORNER = '"+ AllTrim(SFT->FT_CLIEFOR) +"' ) OR (ZGH.ZGH_FORNER = '  ' AND ZGH.ZGH_CLIENT = '  ') ) "//AND ZGH.ZGH_FORLOJ = '"+ AllTrim(SFT->FT_LOJA) +"'
	  EndIf

	  _cQuery += " AND ( ZGH.ZGH_GRUPO = '"+ AllTrim(SB1->B1_GRUPO) +"' OR ZGH.ZGH_PRODUT = '" + AllTrim(SFT->FT_PRODUTO) +"' ) "

	  _cQuery += " AND ( ZGH.ZGH_TPMOV = '"+ AllTrim(SFT->FT_TIPOMOV) +"' OR ZGH.ZGH_CFOP = '" + AllTrim(_xCFOP) +"' ) "

	  _cQuery += " AND ZGH.D_E_L_E_T_	= ' ' "

      If ZGH->(FIELDPOS("ZGH_NATURE")) <> 0
	     _cQuery += " AND ZGH.ZGH_NATURE	= ' ' "
      EndIf

	  _cQuery += " ORDER BY ZGH_CLIENT DESC ,ZGH_FORNER DESC ,ZGH_PRODUT DESC, ZGH_CFOP DESC " //Essa é a orde de prioridade do resltado do SELECT

	  If Select(_cAlias) > 0
	     (_cAlias)->( DBCloseArea() )
	  EndIf

	  DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

	  DBSelectArea(_cAlias)
	  _nConta:=0
 	  
 	  While (_cAlias)->(!Eof())
	                               
	     ZGH->(DBGoTo( (_cAlias)->REC_ZGH ) )
         _nConta++
         If _lEhClente// Se preenchido é Cliente 

            If !Empty(ZGH->ZGH_CLIENT) .And. ZGH->ZGH_CLIENT # SFT->FT_CLIEFOR
               (_cAlias)->(DBSkip())
               Loop 
            EndIf
            If !Empty(ZGH->ZGH_CLILOJ) .And. ZGH->ZGH_CLILOJ # SFT->FT_LOJA
               (_cAlias)->(DBSkip())
               Loop 
            EndIf

         Else

            If !Empty(ZGH->ZGH_FORNER) .And. ZGH->ZGH_FORNER # SFT->FT_CLIEFOR
               (_cAlias)->(DBSkip())
               Loop 
            EndIf    
           
            If !Empty(ZGH->ZGH_FORLOJ) .And. ZGH->ZGH_FORLOJ # SFT->FT_LOJA
               (_cAlias)->(DBSkip())
               Loop 
            EndIf

         EndIf

         If !Empty(ZGH->ZGH_GRUPO) .And. ZGH->ZGH_GRUPO # SB1->B1_GRUPO
            (_cAlias)->(DBSkip())
            Loop 
         ElseIf !Empty(ZGH->ZGH_PRODUT) .And. ZGH->ZGH_PRODUT # SFT->FT_PRODUTO
            (_cAlias)->(DBSkip())
            Loop 
         EndIf

         If !Empty(ZGH->ZGH_TPMOV) .And. ZGH->ZGH_TPMOV # SFT->FT_TIPOMOV
            (_cAlias)->(DBSkip())
            Loop 
         ElseIf !Empty(ZGH->ZGH_CFOP) .And. ZGH->ZGH_CFOP # AllTrim(_xCFOP)
            (_cAlias)->(DBSkip())
            Loop 
         EndIf

		 _cContAju := AllTrim(ZGH->ZGH_CONTA)
	     _nRecZGH  := ZGH->(Recno())//Usada dentro da User Function AFIS008Busca()

		 Exit
      EndDo
	
	  DBSelectArea(_cAlias)
	  (_cAlias)->(DBCloseArea())

      If Empty(_cContAju)
         _cFileNome:="\DATA\ITALAC\CONTROLE\SPEED500.CSV"
	     nHandle:=0
         If File(_cFileNome)
            nHandle:=FOpen(_cFileNome,2)
         EndIf
       
         If nHandle > 0 
            cString := Space(10)
            FReadLn(nHandle,@cString, 10, .F.) 
            If Empty(cString)
               _cLinha:="User;Filial;CFOP;Tipo;Grupo;Produto;Fornecedor;CFOP Original;Recno SFT;Resultado SELECT"+CRLF
               FWrite(nHandle,_cLinha)
            EndIf
         
            _cLinha:=cUserName+";"+SFT->FT_FILIAL+";"+_xCFOP+";"+SFT->FT_TIPOMOV+";"+SB1->B1_GRUPO+";"+SFT->FT_PRODUTO+";"+SFT->FT_CLIEFOR+";"+SFT->FT_CFOP+";"+AllTrim(Str(SFT->(Recno())))+";"+AllTrim(Str(_nConta))+CRLF
            FSEEK(nHandle,0,2)
            FWrite(nHandle,_cLinha)
            FClose(nHandle)
            U_ITCONOUT(_cLinha)
         Else
            U_ITCONOUT("Nao abriu: "+_cFileNome)
         EndIf
      EndIf
   EndIf

End Sequence

SB1->(FWRestArea(_aareaSB1))
SFT->(FWRestArea(_aareaSFT))

Return _cContAju
