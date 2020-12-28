package bootstrap

import (
	"github.com/openshift/installer/pkg/types"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"os"
	"strconv"
)

// SingleNodeBootstrapInPlaceTemplateData is the data to use to replace values in bootstrap template files.
type SingleNodeBootstrapInPlaceTemplateData struct {
	BootstrapInPlace    bool
	CoreosInstallerArgs string
}

// GetSingleNodeBootstrapInPlaceConfig generates the config for the BootstrapInPlace.
func GetSingleNodeBootstrapInPlaceConfig(installConfig *types.InstallConfig) (*SingleNodeBootstrapInPlaceTemplateData, error) {
	bootstrapInPlace, err := isBootstrapInPlace(installConfig)
	if err != nil {
		return nil, err
	}
	if bootstrapInPlace {
		return &SingleNodeBootstrapInPlaceTemplateData{
			BootstrapInPlace:    bootstrapInPlace,
			CoreosInstallerArgs: getCoreosInstallerArgs(),
		}, nil
	}
	return &SingleNodeBootstrapInPlaceTemplateData{}, nil
}

// isBootstrapInPlace checks for bootstrap in place env and validate the number of control plane replica is one
func isBootstrapInPlace(installConfig *types.InstallConfig) (bootstrapInPlace bool, err error) {
	if bootstrapInPlaceEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE"); bootstrapInPlaceEnv != "" {
		bootstrapInPlace, err = strconv.ParseBool(bootstrapInPlaceEnv)
		if err != nil {
			return bootstrapInPlace, err
		}
		if bootstrapInPlace {
			if *installConfig.ControlPlane.Replicas != 1 {
				return bootstrapInPlace, errors.Wrapf(err, "Found OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE env but control plane replica is not 1")
			}
			logrus.Warnf("Creating bootstrap in place configuration")
		}
	}
	return bootstrapInPlace, err
}

// getCoreosInstallerArgs checks for bootstrap in place coreos installer args env
func getCoreosInstallerArgs() string {
	coreosInstallerEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS")
	if coreosInstallerEnv != "" {
		logrus.Warnf("Setting coreos-installer args: %s", coreosInstallerEnv)
	}
	return coreosInstallerEnv
}
