//
//  Recorder.swift
//  SwiftIdentifierExtractorPackageDescription
//
//  Created by KYOHEI UEMURA on 2017/12/07.
//

import Foundation
import AST
import Parser
import Source

class ProjectRecorder{
    public let projectName:String
    public private(set) var idList:IdRecorder?
    public private(set) var fileList:[FileRecorder] = [FileRecorder]()
    public init(projectRootPath root:String){
        projectName=root
        let manager:FileManager = FileManager()
        let result = manager.enumerator(atPath: projectName)
        let filelist = result!.filter { (path:Any) -> Bool in
            let pathStr:String = path as! String
            return pathStr.range(of: ".swift") != nil
        }
        for file in filelist{
            let filerecorder = FileRecorder(fileName: root + (file as! String), projectRootPath: root)
            fileList.append(filerecorder)
        }
    }
    
    public func Save(saveRootPath saveRoot:String){
        getCombinedIdentfierList().SaveIdFiles(saveDirPath: saveRoot)
        for file in fileList{
            file.Save(saveRootDir: saveRoot)
        }
    }
    public func getCombinedIdentfierList() -> IdRecorder{
        if idList == nil {
            idList = IdRecorder()
            for file in fileList{
                idList!.combine(anotherIdRecorder: file.getCombinedIdentifierList())
            }
        }
        return idList!
    }
}

class FileRecorder{
    public let fileName:String
    public let projectRootPath:String
    public private(set) var idList:IdRecorder? = nil
    public private(set) var classList:[ClassRecorder]? = nil
    public init(fileName fn:String, projectRootPath rootPath:String){
        fileName=fn
        projectRootPath=rootPath
        do{
            let cv = ClassVisitor()
            let sourceFile = try SourceReader.read(at: fn)
            let parser = Parser(source: sourceFile)
            let topLevelDecl = try parser.parse()
            try cv.traverse(topLevelDecl)
            classList = cv.classRecorderList
        }
        catch{
            print("Error: \(fileName) can't parse !!")
        }
    }
    
    public func getCombinedIdentifierList() -> IdRecorder{
        if idList == nil{
            idList = IdRecorder()
            for cls in classList!{
                idList!.combine(anotherIdRecorder: cls.idList)
            }
        }
        return idList!
    }
    
    public func Save(saveRootDir rootPath:String){
        let relativePath = fileName.replacingOccurrences(of: projectRootPath, with: "")
        var splitedPath = relativePath.components(separatedBy: "/")
        var dirname = "/[file]" + splitedPath.popLast()!
        var savePath = rootPath + "/[dir]" + splitedPath.joined(separator: "/[dir]") + dirname
        savePath = savePath.replacingOccurrences(of: "//", with: "/")
        CreateDirectory(dirPath: savePath)
        getCombinedIdentifierList().SaveIdFiles(saveDirPath: savePath)
        for cls in classList!{
            let clsDirPath = savePath + "/[cls]" + cls.className
            CreateDirectory(dirPath: clsDirPath)
            cls.idList.SaveIdFiles(saveDirPath: clsDirPath)
            for mthd in cls.methodList{
                let mthdDirPath = clsDirPath + "/[method]" + mthd.methodName
                CreateDirectory(dirPath: mthdDirPath)
                mthd.idList.SaveIdFiles(saveDirPath: mthdDirPath)
            }
        }
    }
    
    private func CreateDirectory(dirPath path:String) -> Bool{
        let manager = FileManager.default
        do{
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true)
            return true
        }
        catch{
            return false
        }
    }
}

class ClassRecorder{
    public let className:String
    public private(set) var idList:IdRecorder
    public private(set) var methodList:[MethodRecorder]
    public init(className cn:String, idList ids:IdRecorder, methodList mtds:[MethodRecorder]){
        className=cn
        idList = ids
        methodList = mtds
    }
}

class MethodRecorder{
    public let methodName:String
    public private(set) var idList:IdRecorder
    
    public init(methodName mn:String, idList ids:IdRecorder){
        methodName=mn
        idList = ids
    }
}

class IdRecorder{
    public private(set) var explicitMemberList = [String]()
    public private(set) var allIdentifireList = [String]()
    public private(set) var identifireList = [String]()
    public private(set) var typeList = [String]()
    public private(set) var functionCallList = [String]()
    public private(set) var constDeclList = [String]()
    public private(set) var varDeclList = [String]()
    public private(set) var paramTypeList = [String]()
    public private(set) var paramExternalNameList = [String]()
    public private(set) var paramLocalNameList = [String]()
    
    public func SaveIdFiles(saveDirPath dir:String){
        SaveIdFile(saveFilePath: dir + "/explicitMember.txt" , idList: explicitMemberList)
        SaveIdFile(saveFilePath: dir + "/allIdentifire.txt" , idList: allIdentifireList)
        SaveIdFile(saveFilePath: dir + "/identifire.txt" , idList: identifireList)
        SaveIdFile(saveFilePath: dir + "/typeList.txt" , idList: typeList)
        SaveIdFile(saveFilePath: dir + "/functionCall.txt" , idList: functionCallList)
        SaveIdFile(saveFilePath: dir + "/constDecl.txt" , idList: constDeclList)
        SaveIdFile(saveFilePath: dir + "/varDecl.txt" , idList: varDeclList)
        SaveIdFile(saveFilePath: dir + "/paramType.txt" , idList: paramTypeList)
        SaveIdFile(saveFilePath: dir + "/paramexternalName.txt" , idList: paramExternalNameList)
        SaveIdFile(saveFilePath: dir + "/paramlocalName.txt" , idList: paramLocalNameList)
    }
    private func SaveIdFile(saveFilePath file:String,idList list:  [String]){
        let data = list.joined(separator: "\n")
        do{
            try data.write(toFile:file.replacingOccurrences(of: "//", with: "/"),atomically: false,encoding: String.Encoding.utf8)
        }
        catch{
            print("Error: \(file) can't write")
        }
    }
    
    public func appendAllIdentifier(identifier id:String){
        allIdentifireList.append(id)
    }

    public func appendIdentifier(identifier id:String){
        identifireList.append(id)
        allIdentifireList.append(id)
    }
    
    public func appendExplicitMember(explicit id:String){
        explicitMemberList.append(id)
        allIdentifireList.append(id)
    }
    public func appendType(type id:String){
        typeList.append(id)
        allIdentifireList.append(id)
    }
    public func appendFunctionCall(function id:String){
        functionCallList.append(id)
        allIdentifireList.append(id)
    }
    public func appendConstDecl(const id:String){
        constDeclList.append(id)
        allIdentifireList.append(id)
    }
    public func appendVariableDecl(variable id:String){
        varDeclList.append(id)
        allIdentifireList.append(id)
    }
    public func appendParamType(type id:String){
        paramTypeList.append(id)
        allIdentifireList.append(id)
    }
    public func appendParamExternalName(externalName id:String){
        paramExternalNameList.append(id)
        allIdentifireList.append(id)
    }
    public func appendParamLocalName(localName id:String){
        paramLocalNameList.append(id)
        allIdentifireList.append(id)
    }
    
    public func combine(anotherIdRecorder recorder:IdRecorder){
        explicitMemberList.append(contentsOf: recorder.explicitMemberList)
        allIdentifireList.append(contentsOf: recorder.allIdentifireList)
        identifireList.append(contentsOf: recorder.identifireList)
        typeList.append(contentsOf: recorder.typeList)
        functionCallList.append(contentsOf: recorder.functionCallList)
        constDeclList.append(contentsOf: recorder.constDeclList)
        varDeclList.append(contentsOf: recorder.varDeclList)
        paramTypeList.append(contentsOf: recorder.paramTypeList)
        paramExternalNameList.append(contentsOf: recorder.paramExternalNameList)
        paramLocalNameList.append(contentsOf: recorder.paramLocalNameList)
    }
}
