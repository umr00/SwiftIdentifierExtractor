import AST
import Parser
import Source
import Foundation

let args = CommandLine.arguments
if args.count != 3{
    print("1st arg: root-directory of target project (absolute path)")
    print("2nd arg: root-directory of saving result ")
    exit(1)
}
let targetPath = args[1]
let savePath = args[2]

let fileManager = FileManager()
if fileManager.fileExists(atPath: targetPath) == false
{
    print("path to target-dir is not exists")
    exit(1)
}
do{
    try fileManager.createDirectory(atPath: savePath, withIntermediateDirectories: true)
}
catch{
    print("path to save-dir can't create")
    exit(1)
}

let projectrecorder = ProjectRecorder(projectRootPath: targetPath)
projectrecorder.Save(saveRootPath: savePath)

