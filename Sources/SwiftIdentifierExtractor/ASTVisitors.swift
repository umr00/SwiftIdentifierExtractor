//
//  ASTVisitors.swift
//  SwiftIdentifierExtractorPackageDescription
//
//  Created by KYOHEI UEMURA on 2017/11/30.
//
import AST
import Parser
import Source
import Foundation

class ClassVisitor : ASTVisitor{
    public private(set) var classRecorderList:[ClassRecorder] = [ClassRecorder]()
    
    func visit(_ classDecl: ClassDeclaration) throws ->Bool{
        let mv = MethodVisitor()
        let methodResult:Bool = try mv.traverse(classDecl)
        if methodResult != true{
            return true
        }
        let iv = IdentVisitor()
        let identResult:Bool = try iv.traverse(classDecl)
        if identResult != true{
            return true
        }
        classRecorderList.append(ClassRecorder(className: classDecl.name, idList: iv.idRecorder, methodList: mv.methodRecorderList))
        return true
    }
    
    func visit(_ extensionDecl:ExtensionDeclaration) throws ->Bool{
        let mv = MethodVisitor()
        let methodResult:Bool = try mv.traverse(extensionDecl)
        if methodResult != true{
            return true
        }
        let iv = IdentVisitor()
        let identResult:Bool = try iv.traverse(extensionDecl)
        if identResult != true{
            return true
        }
        classRecorderList.append(ClassRecorder(className: extensionDecl.type.textDescription, idList: iv.idRecorder, methodList: mv.methodRecorderList))
        return true
    }
}

class MethodVisitor : ASTVisitor{
    public private(set) var methodRecorderList:[MethodRecorder] = [MethodRecorder]()
    func visit(_ method: FunctionDeclaration) throws -> Bool {
        
        let iv = IdentVisitor()
        let traverseResult:Bool = try iv.traverse(method)
        if traverseResult == false {
            return true
        }
        for param in method.signature.parameterList{
            let type = param.typeAnnotation.type.textDescription
            iv.idRecorder.appendParamType(type: type)
            let locName = param.localName.textDescription
            iv.idRecorder.appendParamLocalName(localName: locName)
            if param.externalName != nil{
                let exName = param.externalName!.textDescription
                iv.idRecorder.appendParamExternalName(externalName: exName)
            }
            
        }
        methodRecorderList.append(MethodRecorder(methodName: method.name, idList: iv.idRecorder))
        return true
    }
}
class IdentVisitor : ASTVisitor{

    public let idRecorder = IdRecorder()
    
    func visit(_ id: ExplicitMemberExpression) throws -> Bool {
        let exMember = id.textDescription.components(separatedBy: ".").last!
        idRecorder.appendExplicitMember(explicit: exMember)
        return true
    }
    func visit(_ id: FunctionCallExpression) throws -> Bool {
        let funcCall = id.postfixExpression.textDescription.components(separatedBy: ".").last!
        idRecorder.appendFunctionCall(function: funcCall)
        return true
    }
    func visit(_ id: IdentifierExpression) throws -> Bool {
        idRecorder.appendIdentifier(identifier: id.textDescription)
        return true
    }
    func visit(_ id: VariableDeclaration) throws -> Bool {
        let body = id.body.textDescription
        let varDecl:String
        if body.contains(":"){
            let subs = body.components(separatedBy: ":")
            varDecl = subs[0]
            let type = subs[1].components(separatedBy: "=").first!.replacingOccurrences(of: " ", with: "")
            idRecorder.appendType(type: type)
        }
        else{
            varDecl = body.components(separatedBy: "=").first!.replacingOccurrences(of: " ", with: "")
        }
        idRecorder.appendVariableDecl(variable: varDecl)
        return true
    }
    func visit(_ id: ConstantDeclaration) throws -> Bool {
        let declBody = id.initializerList.first?.pattern.textDescription
        let constDecl:String
        if (declBody?.contains(":"))!{
            let subs = declBody?.components(separatedBy: ":")
            constDecl = subs![0]
            let type = subs![1].replacingOccurrences(of: " ", with: "")
            idRecorder.appendType(type: type)
        }
        else{
            constDecl = declBody!
        }
    
        idRecorder.appendConstDecl(const: constDecl)
        return true
    }
}
