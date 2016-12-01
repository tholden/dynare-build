VERSION=0.1

version () {
    echo "$VERSION"
}

number_of_subfolders () {
    # Returns the number of subfolders in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    #
    # OUTPUTS
    # [1] Number of folders in the directory.
    #
    # Note that the hidden directories are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d | wc -l)
}

number_of_files_with_given_extension () {
    # Returns the number of files with given extension in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Extension.
    #
    # OUTPUTS
    # [1] Number of files with $2 extension in the directory.
    #
    # Note that the hidden files are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -iname "*.$2" -not -path '*/\.*' -type f | wc -l)
}

number_of_folders () {
    # Returns the number of folders in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    #
    # OUTPUTS
    # [1] Number of files with $2 extension in the directory.
    #
    # Note that the hidden folders are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d | wc -l)
}

delete_oldest_files_with_given_extension () {
    # Deletes the oldest files with given extension in a directory, keeping the most recent MAX_NUMBER_OF_FILES files.
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Extension.
    # [3] Number of files to be kept (value of MAX_NUMBER_OF_FILES).
    #
    # OUTPUTS
    # None
    #
    # Note that if the number of files with given extension is less than MAX_NUMBER_OF_FILES, then the function will not
    # do anything.
    local n
    n=$(number_of_files_with_given_extension $1 $2)
    if [ $n -gt $3 ]; then
	local number_of_files_to_be_deleted oldest_files
	number_of_files_to_be_deleted=$(($n-$3))
	oldest_files=$(ls -t1 $1/*.$2 | tail -n $number_of_files_to_be_deleted)
	tput bold; tput setaf 1; echo "I am deleting:"; tput sgr0
	tput setaf 1; echo $oldest_files ; tput sgr0
	rm $oldest_files
    fi
}

delete_oldest_folders () {
    # Deletes the oldest subfolders in a directory, keeping the most recent MAX_NUMBER_OF_FOLDERS folders.
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Number of folders to be kept (value of MAX_NUMBER_OF_FOLDERS).
    #
    # OUTPUTS
    # None
    #
    # Note that if the number of subfolders is less than MAX_NUMBER_OF_FOLDERS, then the function will not
    # do anything.
    local n
    n=$(number_of_folders $1)
    if [ $n -gt $2 ]; then
	local number_of_folders_to_be_deleted oldest_folders 
	number_of_folders_to_be_deleted=$(($n-$2))
	oldest_folders=$(ls -td1 $1/*/ | tail -n $number_of_folders_to_be_deleted)
	tput bold; tput setaf 1; echo "I am deleting:"; tput sgr0
	tput setaf 1; echo $oldest_folders; tput sgr0
	rm -rf $oldest_folders
	echo `pwd`
    fi
}
