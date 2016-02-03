#include "catch.hpp"
#include "set_variable.hpp"
#include "workload.hpp"

#include <bson.h>
#include <bsoncxx/builder/basic/array.hpp>
#include <bsoncxx/builder/basic/document.hpp>
#include <bsoncxx/builder/core.hpp>
#include <bsoncxx/builder/stream/array.hpp>
#include <bsoncxx/builder/stream/document.hpp>
#include <bsoncxx/json.hpp>
#include <bsoncxx/types.hpp>
#include <bsoncxx/types/value.hpp>

using namespace mwg;
using bsoncxx::builder::stream::open_document;
using bsoncxx::builder::stream::close_document;
using bsoncxx::builder::stream::finalize;

TEST_CASE("Set Variables", "[variables]") {
    unordered_map<string, bsoncxx::array::value> wvariables;  // workload variables
    unordered_map<string, bsoncxx::array::value> tvariables;  // thread variables

    wvariables.insert({"workloadVar", bsoncxx::builder::stream::array() << 1 << finalize});
    tvariables.insert({"threadVar", bsoncxx::builder::stream::array() << 2 << finalize});
    mongocxx::client conn{mongocxx::uri{}};

    workload myWorkload;
    threadState state(12234, tvariables, wvariables, myWorkload, "t", "c");

    SECTION("Sanity check setup") {
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 1);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 2);
    }

    SECTION("Set existing thread variable") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : threadVar
    value : 3)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int64().value == 3);
        REQUIRE(state.wvariables.count("threadVar") ==
                0);  // make sure it didn't show up in the wrong place
    }
    SECTION("Set existing workload variable") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    value : 3)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int64().value == 3);
        REQUIRE(state.tvariables.count("workloadVar") ==
                0);  // make sure it didn't show up in the wrong place
    }
    SECTION("Set non-existing variable") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : newVar
    value : 4)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.tvariables.find("newVar")->second.view()[0].get_int64().value == 4);
        REQUIRE(state.wvariables.count("newVar") ==
                0);  // make sure it didn't show up in the wrong place
    }
    SECTION("Set a string value to non-existant variable") {
        auto yaml = YAML::Load(R"yaml(
        type : set_variable
        target : newStringVar
        value : test_string)yaml");

        auto testSet = set_variable(yaml);
        string expected = "test_string";
        testSet.execute(conn, state);
        auto actual = state.tvariables.find("newStringVar")->second.view()[0].get_utf8().value;
        INFO("Expected = \"" << expected << "\"");
        INFO("Got      = \"" << actual << "\"");
        REQUIRE(actual.compare(expected) == 0);
        REQUIRE(state.wvariables.count("newStringVar") ==
                0);  // make sure it didn't show up in the wrong place
    }
    SECTION("Set a string value to existing int") {
        auto yaml = YAML::Load(R"yaml(
        type : set_variable
        target : threadVar
        value : test_string)yaml");

        auto testSet = set_variable(yaml);
        string expected = "test_string";
        testSet.execute(conn, state);
        auto actual = state.tvariables.find("threadVar")->second.view()[0];
        REQUIRE(actual.type() == bsoncxx::type::k_utf8);
        auto actualval = actual.get_utf8().value;
        INFO("Expected = \"" << expected << "\"");
        INFO("Got      = \"" << actualval << "\"");
        REQUIRE(actualval.compare(expected) == 0);
        REQUIRE(state.wvariables.count("threadVar") ==
                0);  // make sure it didn't show up in the wrong place
    }

    SECTION("Set DBName") {
        auto yaml = YAML::Load(R"yaml(
        type : set_variable
        target : DBName
        value : NewDB)yaml");
        // Original database name
        REQUIRE(state.DBName.compare("t") == 0);
        auto testSet = set_variable(yaml);
        string expected = "NewDB";
        testSet.execute(conn, state);
        INFO("Expected = \"" << expected << "\"");
        INFO("Got      = \"" << state.DBName << "\"");
        REQUIRE(state.DBName.compare(expected) == 0);
        REQUIRE(state.wvariables.count("DBName") ==
                0);  // make sure it didn't show up in the wrong place
        REQUIRE(state.tvariables.count("DBName") ==
                0);  // make sure it didn't show up in the wrong place
        REQUIRE(state.CollectionName.compare("c") == 0);
    }

    SECTION("Set CollectionName") {
        auto yaml = YAML::Load(R"yaml(
        type : set_variable
        target : CollectionName
        value : NewColl)yaml");
        // Original database name
        REQUIRE(state.DBName.compare("t") == 0);
        auto testSet = set_variable(yaml);
        string expected = "NewColl";
        testSet.execute(conn, state);
        INFO("Expected = \"" << expected << "\"");
        INFO("Got      = \"" << state.CollectionName << "\"");
        REQUIRE(state.CollectionName.compare(expected) == 0);
        REQUIRE(state.wvariables.count("CollectionName") ==
                0);  // make sure it didn't show up in the wrong place
        REQUIRE(state.tvariables.count("CollectionName") ==
                0);  // make sure it didn't show up in the wrong place
        REQUIRE(state.DBName.compare("t") == 0);
    }

    SECTION("Set from tvariable") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    donorVariable : threadVar)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 2);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 2);
    }
    SECTION("Set from wvariable") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : threadVar
    donorVariable : workloadVar)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 1);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 1);
    }
    SECTION("Use direct value in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 3
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int64().value == 3);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 2);
    }
    SECTION("UseVar in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : usevar
      variable : threadVar
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 2);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 2);
    }
    SECTION("Increment in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : increment
      variable : threadVar
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 2);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 3);
    }
    SECTION("Date in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : date
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].type() ==
                bsoncxx::type::k_date);
    }
    SECTION("Random Int in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : randomint
      min : 50
      max : 60
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].type() ==
                bsoncxx::type::k_int64);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int64().value >= 50);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int64().value < 60);
    }
    SECTION("Random String in operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : randomstring
      length : 11
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].type() ==
                bsoncxx::type::k_utf8);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_utf8().value.length() ==
                11);
    }
    SECTION("Multiply operation") {
        auto yaml = YAML::Load(R"yaml(
    type : set_variable
    target : workloadVar
    operation : 
      type : multiply
      variable : threadVar
      factor : 10
)yaml");

        auto testSet = set_variable(yaml);
        testSet.execute(conn, state);
        REQUIRE(state.wvariables.find("workloadVar")->second.view()[0].get_int32().value == 20);
        REQUIRE(state.tvariables.find("threadVar")->second.view()[0].get_int32().value == 2);
    }
}
